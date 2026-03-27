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
  late TextEditingController _pingIntervalCtrl;

  @override
  void initState() {
    super.initState();
    _pingIntervalCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _pingIntervalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Ping Interval (milliseconds)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            kVSpacer4,
            TextField(
              controller: _pingIntervalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter interval in milliseconds (0 = disabled)',
                border: OutlineInputBorder(
                  borderRadius: kBorderRadius8,
                ),
                isDense: true,
              ),
              onChanged: (value) {
                final interval = int.tryParse(value) ?? 0;
                ref
                    .read(collectionStateNotifierProvider.notifier)
                    .updateWebSocketModel(
                      pingInterval: interval,
                    );
              },
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Information',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            kVSpacer8,
            Container(
              padding: kP12,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: kBorderRadius8,
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Text(
                'Ping intervals help maintain active WebSocket connections by sending periodic ping frames to the server.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
