import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';

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

    return Padding(
      padding: kP12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Send Message Section
          Expanded(
            child: Container(
              padding: kP8,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.blue.withOpacity(0.1) 
                    : Colors.blue.shade50,
                borderRadius: kBorderRadius8,
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.send, size: 18, color: Theme.of(context).colorScheme.primary),
                      kHSpacer8,
                      Text(
                        'Send Message',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      kHSpacer8,
                      if (!isConnected)
                        const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      if (!isConnected)
                        const Text(' (Connect first)',
                            style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ],
                  ),
                  kVSpacer8,
                  Expanded(
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
          ),
        ],
      ),
    );
  }
}
