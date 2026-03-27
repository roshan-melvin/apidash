import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';

enum _WsMessageFilter { all, sent, received }

class EditWebSocketMessagesPane extends ConsumerStatefulWidget {
  const EditWebSocketMessagesPane({super.key});

  @override
  ConsumerState<EditWebSocketMessagesPane> createState() =>
      _EditWebSocketMessagesPaneState();
}

class _EditWebSocketMessagesPaneState
    extends ConsumerState<EditWebSocketMessagesPane> {
  late final TextEditingController _msgCtrl;

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_msgCtrl.text.isEmpty) return;

    final connState = ref.read(webSocketStateProvider).value;
    final isConnected = connState?.isConnected ?? false;

    if (isConnected) {
      ref.read(webSocketServiceProvider).sendMessage(_msgCtrl.text);
      ref.read(collectionStateNotifierProvider.notifier).unsave();
      _msgCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connect before sending messages")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(webSocketStateProvider).value;
    final isConnected = connState?.isConnected ?? false;
    final requestModel = ref.watch(selectedRequestModelProvider);
    final wsModel = requestModel?.websocketRequestModel;
    final savedMessages = wsModel?.savedMessages ?? [];
    final filterIndex = wsModel?.filterIndex ?? 0;

    final messageFilter =
        _WsMessageFilter.values[filterIndex.clamp(0, _WsMessageFilter.values.length - 1)];

    final filteredMessages = savedMessages.where((msg) {
      switch (messageFilter) {
        case _WsMessageFilter.sent:
          return !msg.isIncoming;
        case _WsMessageFilter.received:
          return msg.isIncoming;
        case _WsMessageFilter.all:
          return true;
      }
    }).toList();

    return Padding(
      padding: kP12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Send Message Section
          Container(
            padding: kP8,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: kBorderRadius8,
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.send, size: 18, color: Colors.blue),
                    kHSpacer8,
                    Text(
                      'Send Message',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    kHSpacer8,
                    if (!isConnected)
                      const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    if (!isConnected)
                      const Text('(Connect first)',
                          style: TextStyle(color: Colors.orange, fontSize: 11)),
                  ],
                ),
                kVSpacer8,
                SizedBox(
                  height: 100,
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    enabled: isConnected,
                    decoration: InputDecoration(
                      hintText: isConnected
                          ? 'Enter your message to server here...'
                          : 'Connect to session to send messages',
                      border: OutlineInputBorder(
                        borderRadius: kBorderRadius8,
                      ),
                      isDense: true,
                      contentPadding: kP8,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                kVSpacer8,
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: isConnected ? _send : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: kBorderRadius8,
                      ),
                    ),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Send'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Message History Section
          Row(
            children: [
              const Icon(Icons.history, size: 18),
              kHSpacer8,
              Text(
                'Message History',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              kHSpacer8,
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._WsMessageFilter.values.indexed.map((e) {
                        final isSelected = filterIndex == e.$1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            selected: isSelected,
                            backgroundColor: Colors.grey.shade100,
                            selectedColor: Colors.blue.shade100,
                            label: Text(
                              e.$2.name[0].toUpperCase() +
                                  e.$2.name.substring(1),
                            ),
                            onSelected: (selected) {
                              ref
                                  .read(
                                      collectionStateNotifierProvider.notifier)
                                  .updateWebSocketModel(
                                    filterIndex: e.$1,
                                  );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
          kVSpacer8,
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: kBorderRadius8,
              ),
              child: filteredMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_outlined,
                              size: 32, color: Colors.grey.shade400),
                          kVSpacer8,
                          Text(
                            'No ${messageFilter.name} messages',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredMessages.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final msg = filteredMessages[index];
                        return Padding(
                          padding: kP8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: msg.isIncoming
                                          ? Colors.green.shade100
                                          : Colors.blue.shade100,
                                      borderRadius: kBorderRadius4,
                                    ),
                                    child: Text(
                                      msg.isIncoming ? '↓ Received' : '↑ Sent',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: msg.isIncoming
                                            ? Colors.green.shade900
                                            : Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                  kHSpacer8,
                                  Text(
                                    msg.timestamp
                                        .toString()
                                        .split('.')
                                        .first,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                  ),
                                ],
                              ),
                              kVSpacer4,
                              SelectableText(
                                msg.payload,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
