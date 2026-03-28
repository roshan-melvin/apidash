import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/consts.dart';
import 'package:apidash/widgets/widgets.dart';

class EditWebSocketMessagesPane extends ConsumerStatefulWidget {
  const EditWebSocketMessagesPane({super.key});

  @override
  ConsumerState<EditWebSocketMessagesPane> createState() =>
      _EditWebSocketMessagesPaneState();
}

class _EditWebSocketMessagesPaneState
    extends ConsumerState<EditWebSocketMessagesPane> {
  String _msg = '';
  String _contentType = 'text';
  int _clearCounter = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _send() {
    if (_msg.isEmpty) return;

    final connState = ref.read(webSocketStateProvider).value;
    final isConnected = connState?.isConnected ?? false;

    if (isConnected) {
      ref.read(webSocketServiceProvider).sendMessage(_msg);
      ref.read(collectionStateNotifierProvider.notifier).unsave();
      setState(() {
        _msg = '';
        _clearCounter++;
      });
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
          SizedBox(
            height: kHeaderHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(kLabelSelectContentType),
                kHSpacer8,
                ADDropdownButton<String>(
                  value: _contentType,
                  values: const [('text', 'Text'), ('json', 'JSON')],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _contentType = v;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          kVSpacer8,
          Expanded(
            child: _contentType == 'json'
                ? JsonTextFieldEditor(
                    key: ValueKey("ws-json-body-$_clearCounter"),
                    fieldKey: "ws-json-body-editor",
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    initialValue: _msg,
                    onChanged: (String value) => _msg = value,
                  )
                : TextFieldEditor(
                    key: ValueKey("ws-text-body-$_clearCounter"),
                    fieldKey: "ws-text-body-editor",
                    initialValue: _msg,
                    onChanged: (String value) => _msg = value,
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
    );
  }
}
