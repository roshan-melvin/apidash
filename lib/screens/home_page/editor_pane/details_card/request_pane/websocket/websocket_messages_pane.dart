import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'websocket_template_panel.dart';
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
  bool _isValidJson = true;
  String? _jsonError;
  Timer? _debounceTimer;

  // Templates
  List<Map<String, dynamic>> _templates = [];
  String? _currentRequestId;

  void _checkRequestId(String newId) {
    if (_currentRequestId != newId) {
      _currentRequestId = newId;
      _loadTemplates(newId);
    }
  }

  Future<void> _loadTemplates(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('ws_templates_$requestId');
    if (str != null) {
      try {
        final List<dynamic> list = jsonDecode(str);
        setState(() {
          _templates = list.cast<Map<String, dynamic>>();
        });
      } catch (_) {
        setState(() {
          _templates = [];
        });
      }
    } else {
      setState(() {
        _templates = [];
      });
    }
  }

  Future<void> _saveTemplates() async {
    if (_currentRequestId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ws_templates_$_currentRequestId',
      jsonEncode(_templates),
    );
  }

  void _saveNewTemplate(String name) {
    setState(() {
      _templates.insert(0, {'name': name.trim(), 'payload': _msg});
    });
    _saveTemplates();
  }

  void _deleteTemplate(int index) {
    setState(() {
      _templates.removeAt(index);
    });
    _saveTemplates();
  }

  void _applyTemplate(Map<String, dynamic> t) {
    final payload = t['payload'] ?? '';
    setState(() {
      _msg = payload;
      _clearCounter++;

      try {
        jsonDecode(payload);
        _contentType = 'json';
        _isValidJson = true;
        _jsonError = null;
      } catch (_) {
        _contentType = 'text';
      }
    });
  }

  void _openTemplatesPanel() {
    showDialog(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Material(
            type: MaterialType.transparency,
            child: WebSocketTemplatePanel(
              templates: _templates,
              initialIsSavingView: _templates.isEmpty,
              currentPayload: _msg,
              onClose: () => Navigator.of(ctx).pop(),
              onSave: (name) {
                _saveNewTemplate(name);
                Navigator.of(ctx).pop();
              },
              onDelete: _deleteTemplate,
              onSelect: (t) {
                _applyTemplate(t);
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onMsgChanged(String value) {
    _msg = value;
    if (_contentType == 'json') {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        try {
          if (value.trim().isNotEmpty) {
            jsonDecode(value);
          }
          setState(() {
            _isValidJson = true;
            _jsonError = null;
          });
        } catch (e) {
          setState(() {
            _isValidJson = false;
            _jsonError = e.toString().contains('FormatException:')
                ? e.toString().split('FormatException: ')[1]
                : e.toString();
          });
        }
      });
    }
  }

  void _send() {
    if (_msg.isEmpty) return;

    if (_contentType == 'json') {
      try {
        jsonDecode(_msg);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Invalid JSON format. Please correct it before sending.",
            ),
          ),
        );
        return;
      }
    }

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
    final selectedId = ref.watch(selectedIdStateProvider);
    if (selectedId != null) {
      _checkRequestId(selectedId);
    }
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
                        if (v == 'json') {
                          try {
                            if (_msg.trim().isNotEmpty) jsonDecode(_msg);
                            _isValidJson = true;
                            _jsonError = null;
                          } catch (e) {
                            _isValidJson = false;
                            _jsonError =
                                e.toString().contains('FormatException:')
                                ? e.toString().split('FormatException: ')[1]
                                : e.toString();
                          }
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          kVSpacer8,
          Expanded(
            child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _contentType == 'json' && !_isValidJson
                            ? Theme.of(context).colorScheme.error
                            : Colors.transparent,
                      ),
                      borderRadius: kBorderRadius8,
                    ),
                    child: _contentType == 'json'
                        ? JsonTextFieldEditor(
                            key: ValueKey("ws-json-body-$_clearCounter"),
                            fieldKey: "ws-json-body-editor",
                            isDark:
                                Theme.of(context).brightness == Brightness.dark,
                            initialValue: _msg,
                            onChanged: _onMsgChanged,
                          )
                        : TextFieldEditor(
                            key: ValueKey("ws-text-body-$_clearCounter"),
                            fieldKey: "ws-text-body-editor",
                            initialValue: _msg,
                            onChanged: _onMsgChanged,
                          ),
                  ),
          ),
          if (_contentType == 'json')
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    _msg.trim().isEmpty
                        ? Icons.check_circle
                        : (_isValidJson ? Icons.check_circle : Icons.cancel),
                    size: 14,
                    color: _msg.trim().isEmpty
                        ? Theme.of(context).colorScheme.outline
                        : (_isValidJson
                              ? Colors.green
                              : Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _msg.trim().isEmpty
                          ? 'Enter JSON payload'
                          : (_isValidJson
                                ? 'Valid JSON'
                                : 'Invalid JSON: ${_jsonError ?? ''}'),
                      style: TextStyle(
                        fontSize: 11,
                        color: _msg.trim().isEmpty
                            ? Theme.of(context).colorScheme.outline
                            : (_isValidJson
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          kVSpacer8,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _openTemplatesPanel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: kBorderRadius8),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  icon: Icon(
                    Icons.library_books_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: const Text('Templates'),
                ),
              ),
              kHSpacer8,
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed:
                      (isConnected && (_contentType != 'json' || _isValidJson))
                      ? _send
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: kBorderRadius8),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
