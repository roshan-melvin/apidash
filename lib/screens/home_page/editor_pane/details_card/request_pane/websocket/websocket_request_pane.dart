import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';

class EditWebSocketRequestPane extends ConsumerStatefulWidget {
  const EditWebSocketRequestPane({super.key});

  @override
  ConsumerState<EditWebSocketRequestPane> createState() =>
      _EditWebSocketRequestPaneState();
}

class _EditWebSocketRequestPaneState extends ConsumerState<EditWebSocketRequestPane> {
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
      ref.read(collectionStateNotifierProvider.notifier).unsave(); // explicitly show unsaved changes
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
          Row(
            children: [
              Text('Send Message', style: Theme.of(context).textTheme.titleMedium),
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
          const SizedBox(height: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
