import 'package:apidash_core/apidash_core.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/widgets/widgets.dart';
import '../../common_widgets/common_widgets.dart';
import 'package:apidash/models/models.dart';

class EditorPaneRequestURLCard extends ConsumerWidget {
  const EditorPaneRequestURLCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(selectedIdStateProvider);
    final apiType = ref
        .watch(selectedRequestModelProvider.select((value) => value?.apiType));
    return Card(
      color: kColorTransparent,
      surfaceTintColor: kColorTransparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        borderRadius: kBorderRadius12,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 5,
          horizontal: !context.isMediumWindow ? 20 : 6,
        ),
        child: context.isMediumWindow
            ? Row(
                children: [
                  switch (apiType) {
                    APIType.rest => const DropdownButtonHTTPMethod(),
                    APIType.graphql => kSizedBoxEmpty,
                    APIType.ai => const AIModelSelector(),
                    APIType.mqtt => kSizedBoxEmpty,
                    APIType.websocket => kSizedBoxEmpty,
                    null => kSizedBoxEmpty,
                  },
                  switch (apiType) {
                    APIType.rest => kHSpacer5,
                    _ => kHSpacer8,
                  },
                  const Expanded(
                    child: URLTextField(),
                  ),
                ],
              )
            : Row(
                children: [
                  switch (apiType) {
                    APIType.rest => const DropdownButtonHTTPMethod(),
                    APIType.graphql => kSizedBoxEmpty,
                    APIType.ai => const AIModelSelector(),
                    APIType.mqtt => kSizedBoxEmpty,
                    APIType.websocket => kSizedBoxEmpty,
                    null => kSizedBoxEmpty,
                  },
                  switch (apiType) {
                    APIType.rest => kHSpacer20,
                    _ => kHSpacer8,
                  },
                  const Expanded(
                    child: URLTextField(),
                  ),
                  kHSpacer20,
                  SizedBox(
                    height: 36,
                    child: apiType == APIType.websocket ? const WebSocketConnectButton() : const SendRequestButton(),
                  )
                ],
              ),
      ),
    );
  }
}

class DropdownButtonHTTPMethod extends ConsumerWidget {
  const DropdownButtonHTTPMethod({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(selectedRequestModelProvider
        .select((value) => value?.httpRequestModel?.method));
    return DropdownButtonHttpMethod(
      method: method,
      onChanged: (HTTPVerb? value) {
        ref
            .read(collectionStateNotifierProvider.notifier)
            .update(method: value);
      },
    );
  }
}

class URLTextField extends ConsumerWidget {
  const URLTextField({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedIdStateProvider);
    ref.watch(selectedRequestModelProvider
        .select((value) => value?.aiRequestModel?.url));
    ref.watch(selectedRequestModelProvider
        .select((value) => value?.httpRequestModel?.url));
    ref.watch(selectedRequestModelProvider
        .select((value) => value?.websocketRequestModel?.url));
    final requestModel = ref
        .read(collectionStateNotifierProvider.notifier)
        .getRequestModel(selectedId!)!;
    return EnvURLField(
      selectedId: selectedId,
      initialValue: switch (requestModel.apiType) {
        APIType.ai => requestModel.aiRequestModel?.url,
        APIType.mqtt => requestModel.mqttRequestModel?.brokerUrl,
        APIType.websocket => requestModel.websocketRequestModel?.url,
        _ => requestModel.httpRequestModel?.url,
      },
      onChanged: (value) {
        final latestModel = ref.read(collectionStateNotifierProvider.notifier).getRequestModel(selectedId)!;
        if (latestModel.apiType == APIType.ai) {
          ref.read(collectionStateNotifierProvider.notifier).update(
              aiRequestModel:
                  latestModel.aiRequestModel?.copyWith(url: value));
        } else if (latestModel.apiType == APIType.mqtt) {
          ref.read(collectionStateNotifierProvider.notifier).updateMQTTState(
              id: selectedId,
              mqttRequestModel:
                  latestModel.mqttRequestModel?.copyWith(brokerUrl: value));
        } else if (latestModel.apiType == APIType.websocket) {
          ref.read(collectionStateNotifierProvider.notifier).updateWebSocketState(
              id: selectedId,
              websocketRequestModel:
                  (latestModel.websocketRequestModel ?? const WebSocketRequestModel()).copyWith(url: value));
        } else {
          ref.read(collectionStateNotifierProvider.notifier).update(url: value);
        }
      },
      onFieldSubmitted: (value) {
        ref.read(collectionStateNotifierProvider.notifier).sendRequest();
      },
    );
  }
}

class SendRequestButton extends ConsumerWidget {
  final Function()? onTap;
  const SendRequestButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(selectedIdStateProvider);
    final isWorking = ref.watch(
        selectedRequestModelProvider.select((value) => value?.isWorking));
    final isStreaming = ref.watch(
        selectedRequestModelProvider.select((value) => value?.isStreaming));

    return SendButton(
      isStreaming: isStreaming ?? false,
      isWorking: isWorking ?? false,
      onTap: () {
        onTap?.call();
        ref.read(collectionStateNotifierProvider.notifier).sendRequest();
      },
      onCancel: () {
        ref.read(collectionStateNotifierProvider.notifier).cancelRequest();
      },
    );
  }
}

class WebSocketConnectButton extends ConsumerStatefulWidget {
  const WebSocketConnectButton({super.key});

  @override
  ConsumerState<WebSocketConnectButton> createState() => _WebSocketConnectButtonState();
}

class _WebSocketConnectButtonState extends ConsumerState<WebSocketConnectButton> {
  bool _isConnecting = false;

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    final wsService = ref.read(webSocketServiceProvider);
    final requestModel = ref.read(selectedRequestModelProvider);
    if (requestModel == null) {
      if (mounted) setState(() => _isConnecting = false);
      return;
    }
    final latestModel = ref.read(collectionStateNotifierProvider.notifier).getRequestModel(requestModel.id)!;
    final request = latestModel.websocketRequestModel ?? const WebSocketRequestModel();
    await wsService.connect(request);
    if (mounted) {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    await ref.read(webSocketServiceProvider).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(webSocketStateProvider).value;
    final isConnected = connState?.isConnected ?? false;
    final isConnecting = connState?.isConnecting ?? false;
    final showLoading = _isConnecting || isConnecting;

    return FilledButton.icon(
      onPressed: showLoading ? null : (isConnected ? _disconnect : _connect),
      style: FilledButton.styleFrom(
        backgroundColor: isConnected
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        foregroundColor: isConnected
            ? Theme.of(context).colorScheme.onError
            : Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: kBorderRadius8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(100, 36),
      ),
      icon: showLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          : Icon(
              isConnected ? Icons.cable : Icons.rocket_launch,
              size: 16,
            ),
      label: Text(
        isConnected ? 'Disconnect' : (showLoading ? 'Connecting...' : 'Connect'),
        style: kTextStyleButton,
      ),
    );
  }
}
