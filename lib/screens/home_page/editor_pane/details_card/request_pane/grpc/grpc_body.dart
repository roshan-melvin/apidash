import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/widgets/widgets.dart';
import 'package:apidash/screens/home_page/editor_pane/details_card/request_pane/websocket/websocket_template_panel.dart';

class GrpcBody extends ConsumerStatefulWidget {
  const GrpcBody({super.key});

  @override
  ConsumerState<GrpcBody> createState() => _GrpcBodyState();
}

class _GrpcBodyState extends ConsumerState<GrpcBody> {
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
    final str = prefs.getString('grpc_templates_$requestId');
    if (str != null) {
      try {
        final List<dynamic> list = jsonDecode(str);
        if (mounted) {
          setState(() {
            _templates = list.cast<Map<String, dynamic>>();
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _templates = [];
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _templates = [];
        });
      }
    }
  }

  Future<void> _saveTemplates() async {
    if (_currentRequestId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'grpc_templates_$_currentRequestId',
      jsonEncode(_templates),
    );
  }

  void _saveNewTemplate(String name, String currentPayload) {
    setState(() {
      _templates.insert(0, {'name': name.trim(), 'payload': currentPayload});
    });
    _saveTemplates();
  }

  void _deleteTemplate(int index) {
    setState(() {
      _templates.removeAt(index);
    });
    _saveTemplates();
  }

  void _applyTemplate(
    Map<String, dynamic> template,
    String selectedId,
    WidgetRef ref,
  ) {
    final newPayload = template['payload'] ?? '';
    ref
        .read(collectionStateNotifierProvider.notifier)
        .updateGrpcModel(id: selectedId, requestJson: newPayload);
  }

  void _openTemplatesPanel(
    BuildContext ctx,
    String currentPayload,
    String selectedId,
    WidgetRef ref,
  ) {
    showDialog(
      context: ctx,
      barrierColor: Theme.of(ctx).colorScheme.scrim.withValues(alpha: 0.5),
      builder: (context) {
        return WebSocketTemplatePanel(
          templates: _templates,
          initialIsSavingView: false,
          currentPayload: currentPayload,
          onClose: () => Navigator.of(context).pop(),
          onSave: (name) {
            _saveNewTemplate(name, currentPayload);
            Navigator.of(context).pop();
          },
          onDelete: _deleteTemplate,
          onSelect: (t) {
            _applyTemplate(t, selectedId, ref);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedIdStateProvider);
    if (selectedId != null) {
      _checkRequestId(selectedId);
    }
    final requestModel = ref.watch(
      collectionStateNotifierProvider.select(
        (value) => value?[selectedId]?.grpcRequestModel,
      ),
    );
    final darkMode = ref.watch(
      settingsProvider.select((value) => value.isDark),
    );

    if (requestModel == null) {
      return const SizedBox.shrink();
    }

    final grpcState = ref.watch(grpcStateProvider);
    final isActiveUrlConnected =
        (grpcState.value?.isConnected ?? false) &&
        (grpcState.value?.connectedUrl == requestModel.url);

    // Extract services and methods
    List<String> services = [];
    List<String> methodsForSelectedService = [];
    final descriptors = grpcState.value?.descriptors;

    if (descriptors != null) {
      for (final fd in descriptors.values) {
        if (fd.service.isNotEmpty) {
          for (final s in fd.service) {
            String fullServiceName = fd.package.isNotEmpty
                ? '${fd.package}.${s.name}'
                : s.name;
            if (!services.contains(fullServiceName)) {
              services.add(fullServiceName);
            }
            if (requestModel.serviceName == fullServiceName) {
              for (final m in s.method) {
                methodsForSelectedService.add(m.name);
              }
            }
          }
        }
      }
    }

    String? currentService = requestModel.serviceName;
    if (currentService.isNotEmpty && !services.contains(currentService)) {
      services.add(currentService);
    }
    if (services.isEmpty && currentService.isNotEmpty) {
      services.add(currentService);
    }

    String? currentMethod = requestModel.methodName;
    if (currentMethod.isNotEmpty &&
        !methodsForSelectedService.contains(currentMethod)) {
      methodsForSelectedService.add(currentMethod);
    }

    return Padding(
      padding: kPt5o10.copyWith(bottom: 10, left: 20, right: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Service",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    kVSpacer5,
                    Container(
                      height: 36,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          isDense: true,
                          value: currentService.isEmpty ? null : currentService,
                          items: services.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Tooltip(
                                message: value,
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              ref
                                  .read(
                                    collectionStateNotifierProvider.notifier,
                                  )
                                  .updateGrpcModel(
                                    id: selectedId!,
                                    serviceName: newValue,
                                    methodName:
                                        "", // Reset method when service changes
                                  );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              kHSpacer10,
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Method",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    kVSpacer5,
                    Container(
                      height: 36,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          isDense: true,
                          value: currentMethod.isEmpty ? null : currentMethod,
                          items: methodsForSelectedService.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Tooltip(
                                message: value,
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              ref
                                  .read(
                                    collectionStateNotifierProvider.notifier,
                                  )
                                  .updateGrpcModel(
                                    id: selectedId!,
                                    methodName: newValue,
                                  );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          kVSpacer10,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Payload",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(
                height: 32,
                child: TextButton.icon(
                  onPressed: () => _openTemplatesPanel(
                    context,
                    requestModel.requestJson,
                    selectedId!,
                    ref,
                  ),
                  icon: Icon(
                    Icons.library_books_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    'Templates',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          kVSpacer5,
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: kBorderRadius8,
              ),
              child: JsonTextFieldEditor(
                key: Key("grpc_body_$selectedId"),
                fieldKey: "grpc_body_$selectedId-editor-$darkMode",
                isDark: darkMode,
                initialValue: requestModel.requestJson,
                onChanged: (String value) {
                  ref
                      .read(collectionStateNotifierProvider.notifier)
                      .updateGrpcModel(id: selectedId, requestJson: value);
                },
                hintText: "Enter JSON body for gRPC payload...",
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isActiveUrlConnected
                  ? () async {
                      final message = requestModel.requestJson;
                      if (message.isNotEmpty) {
                        await ref
                            .read(grpcServiceProvider)
                            .send(message: message, requestModel: requestModel);
                      } else {
                        await ref
                            .read(grpcServiceProvider)
                            .send(message: "{}", requestModel: requestModel);
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: kBorderRadius8,
                ),
              ),
              icon: const Icon(Icons.send),
              label: const Text("Send"),
            ),
          ),
        ],
      ),
    );
  }
}
