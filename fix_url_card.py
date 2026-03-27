import re

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/url_card.dart', 'r') as f:
    text = f.read()

# First, remove any MQTTPortField or MQTTConnectButton subclasses so we don't have duplicates
start_idx = text.find('class MQTTPortField extends ConsumerWidget {')
if start_idx != -1:
    text = text[:start_idx]

mqtt_components = """
class MQTTPortField extends ConsumerWidget {
  const MQTTPortField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref
        .watch(collectionStateNotifierProvider.notifier)
        .getRequestModel(selectedId!)!;
    
    final connState = ref.watch(mqttConnectionStateProvider).value;
    final isConnected = connState?.isConnected ?? false;

    return SizedBox(
      width: 72,
      child: TextFormField(
        initialValue: requestModel.mqttRequestModel?.port.toString() ?? '1883',
        enabled: !isConnected,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: '1883',
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: kBorderRadius8,
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          isDense: true,
        ),
        onChanged: (v) {
          final port = int.tryParse(v) ?? 1883;
          final latestModel = ref.read(collectionStateNotifierProvider.notifier).getRequestModel(selectedId)!;
          ref.read(collectionStateNotifierProvider.notifier).updateMQTTState(
              id: selectedId,
              mqttRequestModel:
                  latestModel.mqttRequestModel?.copyWith(port: port));
        },
      ),
    );
  }
}

class MQTTConnectButton extends ConsumerStatefulWidget {
  const MQTTConnectButton({super.key});

  @override
  ConsumerState<MQTTConnectButton> createState() => _MQTTConnectButtonState();
}

class _MQTTConnectButtonState extends ConsumerState<MQTTConnectButton> {
  bool _isConnecting = false;

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    try {
      final mqttService = ref.read(mqttServiceProvider);
      final requestModel = ref.read(selectedRequestModelProvider);
      if (requestModel == null) {
        if (mounted) setState(() => _isConnecting = false);
        return;
      }
      final latestModel = ref.read(collectionStateNotifierProvider.notifier).getRequestModel(requestModel.id)!;
      final request = latestModel.mqttRequestModel ?? const MQTTRequestModel();
      await mqttService.connect(request);
    } catch(e) {
      debugPrint("MQTT connect layout error: $e");
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    await ref.read(mqttServiceProvider).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(mqttConnectionStateProvider).value;
    
    final isReconnecting = connState?.isReconnecting ?? false;
    final isConnecting = _isConnecting || isReconnecting;
    
    final isConnected = connState?.isConnected ?? false;
    final showLoading = isConnecting;

    return FilledButton.icon(
      onPressed: showLoading ? null : (isConnected ? _disconnect : _connect),
      style: FilledButton.styleFrom(
        backgroundColor: isConnected
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        foregroundColor: isConnected
            ? Theme.of(context).colorScheme.onError
            : Theme.of(context).colorScheme.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: kBorderRadius8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(100, 36),
      ),
      icon: showLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            )
          : Icon(
              isConnected ? Icons.cable : Icons.rocket_launch,
              size: 16,
            ),
      label: Text(
        isConnected ? 'Disconnect' : (showLoading ? 'Connecting...' : 'Connect'),
        style: kTextStyleButton,
      ),
    );
  }
}
"""

text = text + mqtt_components

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/url_card.dart', 'w') as f:
    f.write(text)

