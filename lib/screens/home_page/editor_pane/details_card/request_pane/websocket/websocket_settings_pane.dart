import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash/providers/providers.dart';

class EditWebSocketSettingsPane extends ConsumerStatefulWidget {
  const EditWebSocketSettingsPane({super.key});

  @override
  ConsumerState<EditWebSocketSettingsPane> createState() =>
      _EditWebSocketSettingsPaneState();
}

class _EditWebSocketSettingsPaneState
    extends ConsumerState<EditWebSocketSettingsPane> {
  @override
  Widget build(BuildContext context) {
    final activeRequestModel = ref.watch(selectedRequestModelProvider);
    final wsModel = activeRequestModel?.websocketRequestModel;
    if (wsModel == null) return const SizedBox.shrink();

    final clrScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: kP12,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connection Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Ping Interval
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ping Interval (seconds)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller:
                        TextEditingController(
                            text: wsModel.pingInterval.toString(),
                          )
                          ..selection = TextSelection.collapsed(
                            offset: wsModel.pingInterval.toString().length,
                          ),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0 = disabled',
                      border: OutlineInputBorder(borderRadius: kBorderRadius8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final interval = int.tryParse(value) ?? 0;
                      ref
                          .read(collectionStateNotifierProvider.notifier)
                          .updateWebSocketModel(pingInterval: interval);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Auto Reconnect Toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Auto Reconnect',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Switch(
                  value: wsModel.autoReconnect,
                  onChanged: (val) {
                    ref
                        .read(collectionStateNotifierProvider.notifier)
                        .updateWebSocketModel(autoReconnect: val);
                  },
                ),
              ],
            ),

            if (wsModel.autoReconnect) ...[
              const SizedBox(height: 16),
              // Reconnect Interval
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reconnect Interval (s)',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller:
                          TextEditingController(
                              text: wsModel.reconnectInterval.toString(),
                            )
                            ..selection = TextSelection.collapsed(
                              offset: wsModel.reconnectInterval
                                  .toString()
                                  .length,
                            ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        var interval = int.tryParse(value) ?? 5;
                        if (interval < 1) interval = 1;
                        if (interval > 60) interval = 60;
                        ref
                            .read(collectionStateNotifierProvider.notifier)
                            .updateWebSocketModel(reconnectInterval: interval);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Max Retries
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Max Retries (0 = unlimited)',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller:
                          TextEditingController(
                              text: wsModel.maxRetries.toString(),
                            )
                            ..selection = TextSelection.collapsed(
                              offset: wsModel.maxRetries.toString().length,
                            ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final retries = int.tryParse(value) ?? 5;
                        ref
                            .read(collectionStateNotifierProvider.notifier)
                            .updateWebSocketModel(
                              maxRetries: retries > 0 ? retries : 0,
                            );
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            Divider(color: clrScheme.outlineVariant.withAlpha(100)),
            const SizedBox(height: 12),
            Container(
              padding: kP12,
              decoration: BoxDecoration(
                color: clrScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: kBorderRadius8,
                border: Border.all(
                  color: clrScheme.outlineVariant.withAlpha(100),
                ),
              ),
              child: Text(
                'Autoreconnect activates automatically if a connected socket drops. Manually disconnecting prevents auto reconnect attempts.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: clrScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
