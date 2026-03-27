import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/widgets/widgets.dart';
import 'websocket_messages_pane.dart';
import 'websocket_request_headers.dart';
import 'websocket_settings_pane.dart';

class EditWebSocketRequestPane extends ConsumerWidget {
  const EditWebSocketRequestPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final codePaneVisible = ref.watch(codePaneVisibleStateProvider);
    final tabIndex = ref.watch(selectedRequestModelProvider
        .select((value) => value?.websocketRequestModel?.requestTabIndex));
    final requestModel = ref.watch(selectedRequestModelProvider);
    final wsModel = requestModel?.websocketRequestModel;

    final headerLength = wsModel?.requestHeaders?.length ?? 0;

    return RequestPane(
      selectedId: selectedId,
      showViewCodeButton: false,
      codePaneVisible: codePaneVisible,
      tabIndex: tabIndex,
      onPressedCodeButton: () {
        ref.read(codePaneVisibleStateProvider.notifier).state =
            !codePaneVisible;
      },
      onTapTabBar: (index) {
        ref
            .read(collectionStateNotifierProvider.notifier)
            .updateWebSocketModel(requestTabIndex: index);
      },
      showIndicators: [
        false, // Messages
        headerLength > 0, // Headers
        false, // Settings
      ],
      tabLabels: const [
        'Messages',
        'Headers',
        'Settings',
      ],
      children: const [
        EditWebSocketMessagesPane(),
        EditWebSocketRequestHeaders(),
        EditWebSocketSettingsPane(),
      ],
    );
  }
}
