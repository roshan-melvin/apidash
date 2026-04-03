import 'package:apidash/models/mqtt_request_model.dart';
import 'package:apidash_core/apidash_core.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/widgets/widgets.dart';
import '../../common_widgets/common_widgets.dart';
import 'package:apidash/models/models.dart';
import 'package:apidash/utils/utils.dart';

class EditorPaneRequestURLCard extends ConsumerWidget {
  const EditorPaneRequestURLCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(selectedIdStateProvider);
    final apiType = ref.watch(
      selectedRequestModelProvider.select((value) => value?.apiType),
    );
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
                    APIType.mqtt => const DropdownButtonMQTTProtocol(),
                    APIType.websocket => kSizedBoxEmpty,
                    APIType.grpc => kSizedBoxEmpty,
                    null => kSizedBoxEmpty,
                  },
                  switch (apiType) {
                    APIType.rest => kHSpacer5,
                    _ => kHSpacer8,
                  },
                  const Expanded(child: URLTextField()),
                  switch (apiType) {
                    APIType.mqtt => const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: MQTTPortField(),
                    ),
                    _ => kSizedBoxEmpty,
                  },
                ],
              )
            : Row(
                children: [
                  switch (apiType) {
                    APIType.rest => const DropdownButtonHTTPMethod(),
                    APIType.graphql => kSizedBoxEmpty,
                    APIType.ai => const AIModelSelector(),
                    APIType.mqtt => const DropdownButtonMQTTProtocol(),
                    APIType.websocket => kSizedBoxEmpty,
                    APIType.grpc => kSizedBoxEmpty,
                    null => kSizedBoxEmpty,
                  },
                  switch (apiType) {
                    APIType.rest => kHSpacer20,
                    _ => kHSpacer8,
                  },
                  const Expanded(child: URLTextField()),
                  switch (apiType) {
                    APIType.mqtt => const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: MQTTPortField(),
                    ),
                    _ => kSizedBoxEmpty,
                  },
                  kHSpacer20,
                  SizedBox(
                    height: 36,
                    child: apiType == APIType.mqtt
                        ? const MQTTConnectButton()
                        : (apiType == APIType.websocket
                              ? const WebSocketConnectButton()
                              : (apiType == APIType.grpc
                                    ? const GrpcInvokeButton()
                                    : const SendRequestButton())),
                  ),
                ],
              ),
      ),
    );
  }
}

class DropdownButtonHTTPMethod extends ConsumerWidget {
  const DropdownButtonHTTPMethod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(
      selectedRequestModelProvider.select(
        (value) => value?.httpRequestModel?.method,
      ),
    );
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
  const URLTextField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedIdStateProvider);
    ref.watch(
      selectedRequestModelProvider.select(
        (value) => value?.aiRequestModel?.url,
      ),
    );
    ref.watch(
      selectedRequestModelProvider.select(
        (value) => value?.httpRequestModel?.url,
      ),
    );
    ref.watch(
      selectedRequestModelProvider.select(
        (value) => value?.websocketRequestModel?.url,
      ),
    );
    final requestModel = ref
        .read(collectionStateNotifierProvider.notifier)
        .getRequestModel(selectedId!)!;
    return EnvURLField(
      selectedId: selectedId,
      initialValue: switch (requestModel.apiType) {
        APIType.ai => requestModel.aiRequestModel?.url,
        APIType.mqtt => requestModel.mqttRequestModel?.brokerUrl,
        APIType.websocket => requestModel.websocketRequestModel?.url,
        APIType.grpc => requestModel.grpcRequestModel?.url,
        _ => requestModel.httpRequestModel?.url,
      },
      onChanged: (value) {
        final latestModel = ref
            .read(collectionStateNotifierProvider.notifier)
            .getRequestModel(selectedId)!;
        if (latestModel.apiType == APIType.ai) {
          ref
              .read(collectionStateNotifierProvider.notifier)
              .update(
                aiRequestModel: latestModel.aiRequestModel?.copyWith(
                  url: value,
                ),
              );
        } else if (latestModel.apiType == APIType.mqtt) {
          ref
              .read(collectionStateNotifierProvider.notifier)
              .updateMQTTState(
                id: selectedId,
                mqttRequestModel: latestModel.mqttRequestModel?.copyWith(
                  brokerUrl: value,
                ),
              );
        } else if (latestModel.apiType == APIType.websocket) {
          ref
              .read(collectionStateNotifierProvider.notifier)
              .updateWebSocketState(
                id: selectedId,
                websocketRequestModel:
                    (latestModel.websocketRequestModel ??
                            const WebSocketRequestModel())
                        .copyWith(url: value),
              );
        } else if (latestModel.apiType == APIType.grpc) {
          ref
              .read(collectionStateNotifierProvider.notifier)
              .updateGrpcModel(id: selectedId, url: value);
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
  const SendRequestButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(selectedIdStateProvider);
    final isWorking = ref.watch(
      selectedRequestModelProvider.select((value) => value?.isWorking),
    );
    final isStreaming = ref.watch(
      selectedRequestModelProvider.select((value) => value?.isStreaming),
    );

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
  final Function()? onTap;
  const WebSocketConnectButton({super.key, this.onTap});

  @override
  ConsumerState<WebSocketConnectButton> createState() =>
      _WebSocketConnectButtonState();
}

class _WebSocketConnectButtonState
    extends ConsumerState<WebSocketConnectButton> {
  bool _isConnecting = false;

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    try {
      final wsService = ref.read(webSocketServiceProvider);
      final requestModel = ref.read(selectedRequestModelProvider);
      if (requestModel == null) {
        if (mounted) setState(() => _isConnecting = false);
        return;
      }
      final latestModel = ref
          .read(collectionStateNotifierProvider.notifier)
          .getRequestModel(requestModel.id)!;
      final request =
          latestModel.websocketRequestModel ?? const WebSocketRequestModel();
      await wsService.connect(request);
    } catch (e) {
      debugPrint("WebSocket connect layout error: $e");
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    await ref.read(webSocketServiceProvider).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(webSocketStateProvider).value;
    final activeRequestModel = ref
        .watch(selectedRequestModelProvider)
        ?.websocketRequestModel;
    final activeUrl = activeRequestModel?.url ?? '';

    // Check if globally connected AND connected to the exact same URL as the active tab
    final isActiveUrlConnected =
        (connState?.isConnected ?? false) &&
        (connState?.connectedUrl == activeUrl);

    // Check if globally connecting to the exact same URL
    // (We don't strictly have connectingUrl, but _isConnecting handles the local button state)
    final isConnecting = connState?.isConnecting ?? false;
    final showLoading =
        _isConnecting ||
        isConnecting &&
            (connState?.connectedUrl == null ||
                connState?.connectedUrl == activeUrl);

    // If it's connected globally but to a DIFFERENT url, we treat this tab as not connected
    final isConnected = isActiveUrlConnected;

    final btn = FilledButton.icon(
      onPressed: showLoading ? null : (isConnected ? _disconnect : _connect),
      style: FilledButton.styleFrom(
        backgroundColor: isConnected
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        foregroundColor: isConnected
            ? Theme.of(context).colorScheme.onError
            : Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(100, 36),
      ),
      icon: showLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          : Icon(isConnected ? Icons.cable : Icons.rocket_launch, size: 16),
      label: Text(
        isConnected
            ? 'Disconnect'
            : (showLoading ? 'Connecting...' : 'Connect'),
        style: kTextStyleButton,
      ),
    );

    if (showLoading && !isConnected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn,
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              ref.read(webSocketServiceProvider).disconnect();
              setState(() => _isConnecting = false);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              shape: const RoundedRectangleBorder(borderRadius: kBorderRadius8),
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
            child: const Icon(Icons.close, size: 18),
          ),
        ],
      );
    }
    return btn;
  }
}

class GrpcInvokeButton extends ConsumerStatefulWidget {
  final Function()? onTap;
  const GrpcInvokeButton({super.key, this.onTap});

  @override
  ConsumerState<GrpcInvokeButton> createState() => _GrpcInvokeButtonState();
}

class _GrpcInvokeButtonState extends ConsumerState<GrpcInvokeButton> {
  void _connect() async {
    try {
      final activeRequestModel = ref.read(grpcRequestProvider);
      await ref.read(grpcServiceProvider).connect(activeRequestModel);
    } catch (e) {
      debugPrint("gRPC connect panel error: $e");
    }
  }

  void _disconnect() {
    ref.read(grpcServiceProvider).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final grpcState = ref.watch(grpcStateProvider);
    final activeRequestModel = ref.watch(
      collectionStateNotifierProvider.select(
        (v) => v?[ref.watch(selectedIdStateProvider)]?.grpcRequestModel,
      ),
    );

    final isActiveUrlConnected =
        (grpcState.value?.isConnected ?? false) &&
        (grpcState.value?.connectedUrl == activeRequestModel?.url);
    final isConnecting = grpcState.value?.isConnecting ?? false;

    final showLoading =
        isConnecting &&
        (grpcState.value?.connectedUrl == null ||
            grpcState.value?.connectedUrl == activeRequestModel?.url);

    final isConnected = isActiveUrlConnected;

    final btn = isConnected
        ? FilledButton.icon(
            onPressed: () {
              _disconnect();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: const RoundedRectangleBorder(borderRadius: kBorderRadius8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(100, 36),
            ),
            icon: const Icon(Icons.cable, size: 16),
            label: const Text('Disconnect', style: kTextStyleButton),
          )
        : FilledButton.icon(
            onPressed: showLoading ? null : () {
              widget.onTap?.call();
              _connect();
            },
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: kBorderRadius8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(100, 36),
            ),
            icon: showLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : const Icon(Icons.rocket_launch, size: 16),
            label: Text(
              showLoading ? 'Connecting...' : 'Connect',
              style: kTextStyleButton,
            ),
          );

    if (showLoading && !isConnected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn,
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              _disconnect();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              shape: const RoundedRectangleBorder(borderRadius: kBorderRadius8),
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
            child: const Icon(Icons.close, size: 18),
          ),
        ],
      );
    }

    return btn;
  }
}

class MQTTPortField extends ConsumerWidget {
  const MQTTPortField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref
        .watch(collectionStateNotifierProvider.notifier)
        .getRequestModel(selectedId!)!;

    final connState = ref.watch(mqttConnectionStateProvider).value;
    final isConnected = connState?.isConnected ?? false;

    return SizedBox(
      width: 72,
      child: TextFormField(
        initialValue: requestModel.mqttRequestModel?.port.toString() ?? '1883',
        enabled: !isConnected,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: '1883',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: kBorderRadius8,
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: kBorderRadius8,
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: kBorderRadius8,
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          isDense: true,
        ),
        onChanged: (v) {
          final port = int.tryParse(v) ?? 1883;
          final latestModel = ref
              .read(collectionStateNotifierProvider.notifier)
              .getRequestModel(selectedId)!;
          ref
              .read(collectionStateNotifierProvider.notifier)
              .updateMQTTState(
                id: selectedId,
                mqttRequestModel: latestModel.mqttRequestModel?.copyWith(
                  port: port,
                ),
              );
        },
      ),
    );
  }
}

class MQTTConnectButton extends ConsumerStatefulWidget {
  final Function()? onTap;
  const MQTTConnectButton({super.key, this.onTap});

  @override
  ConsumerState<MQTTConnectButton> createState() => _MQTTConnectButtonState();
}

class _MQTTConnectButtonState extends ConsumerState<MQTTConnectButton> {
  bool _isConnecting = false;

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    try {
      final mqttService = ref.read(mqttServiceProvider);
      final requestModel = ref.read(selectedRequestModelProvider);
      if (requestModel == null) {
        if (mounted) setState(() => _isConnecting = false);
        return;
      }
      final latestModel = ref
          .read(collectionStateNotifierProvider.notifier)
          .getRequestModel(requestModel.id)!;
      final request = latestModel.mqttRequestModel ?? const MQTTRequestModel();
      await mqttService.connect(request);
    } catch (e) {
      debugPrint("MQTT connect layout error: $e");
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    await ref.read(mqttServiceProvider).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(mqttConnectionStateProvider).value;

    final isReconnecting = connState?.isReconnecting ?? false;
    final isConnecting = _isConnecting || isReconnecting;

    final isConnected = connState?.isConnected ?? false;
    final showLoading = isConnecting;

    final btn = FilledButton.icon(
      onPressed: showLoading ? null : (isConnected ? _disconnect : _connect),
      style: FilledButton.styleFrom(
        backgroundColor: isConnected
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        foregroundColor: isConnected
            ? Theme.of(context).colorScheme.onError
            : Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(100, 36),
      ),
      icon: showLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          : Icon(isConnected ? Icons.cable : Icons.rocket_launch, size: 16),
      label: Text(
        isConnected
            ? 'Disconnect'
            : (showLoading ? 'Connecting...' : 'Connect'),
        style: kTextStyleButton,
      ),
    );

    if (showLoading && !isConnected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn,
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              _disconnect();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              shape: const RoundedRectangleBorder(borderRadius: kBorderRadius8),
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
            child: const Icon(Icons.close, size: 18),
          ),
        ],
      );
    }
    return btn;
  }
}

class DropdownButtonMQTTProtocol extends ConsumerWidget {
  const DropdownButtonMQTTProtocol({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final protocolVersion = ref.watch(
      selectedRequestModelProvider.select(
        (value) =>
            value?.mqttRequestModel?.protocolVersion ??
            MQTTProtocolVersion.v311,
      ),
    );
    final connState = ref.watch(mqttConnectionStateProvider).value;
    final isConnected = connState?.isConnected ?? false;

    return DropdownButtonHideUnderline(
      child: ADDropdownButton<MQTTProtocolVersion>(
        value: protocolVersion,
        values: MQTTProtocolVersion.values.map((v) {
          return (
            v,
            v == MQTTProtocolVersion.v31
                ? 'V3.1'
                : v == MQTTProtocolVersion.v311
                ? 'V3.1.1'
                : 'V5.0',
          );
        }).toList(),
        onChanged: isConnected
            ? null
            : (MQTTProtocolVersion? value) {
                if (value != null && selectedId != null) {
                  final latestModel = ref
                      .read(collectionStateNotifierProvider.notifier)
                      .getRequestModel(selectedId)!;
                  ref
                      .read(collectionStateNotifierProvider.notifier)
                      .updateMQTTState(
                        id: selectedId,
                        mqttRequestModel: latestModel.mqttRequestModel
                            ?.copyWith(protocolVersion: value),
                      );
                }
              },
        dropdownMenuItemPadding: EdgeInsets.only(
          left: context.isMediumWindow ? 8 : 16,
        ),
        dropdownMenuItemtextStyle: (MQTTProtocolVersion v) =>
            kCodeStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: getAPIColor(
                APIType.mqtt,
                brightness: Theme.of(context).brightness,
              ),
            ),
      ),
    );
  }
}
