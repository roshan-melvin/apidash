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
          Row(
            children: [
              Text(
                'Messages',
                style: Theme.of(context).textTheme.titleMedium,
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
                            label: Text(e.$2.name[0].toUpperCase() +
                                e.$2.name.substring(1)),
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
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: kBorderRadius8,
              ),
              child: filteredMessages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.grey.shade600),
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
                                      msg.isIncoming ? 'Received' : 'Sent',
                                      style: TextStyle(
                                        fontSize: 12,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Send Message',
                  style: Theme.of(context).textTheme.titleMedium),
              kHSpacer8,
              if (!isConnected)
                const Icon(Icons.info_outline, size: 16, color: Colors.orange),
              if (!isConnected)
                kHSpacer4,
              if (!isConnected)
                const Text('Connect to session to send messages',
                    style: TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ),
          kVSpacer8,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message to server here...',
                      border: OutlineInputBorder(
                        borderRadius: kBorderRadius8,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                kHSpacer12,
                FilledButton.icon(
                  onPressed: isConnected ? _send : null,
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: kBorderRadius8,
                    ),
                  ),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
