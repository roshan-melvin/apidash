import re

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'r') as f:
    text = f.read()

# remove `bool _isConnecting = false;`
text = re.sub(r"bool _isConnecting = false;\n", "", text)
text = re.sub(r"late final TextEditingController _brokerCtrl;\n", "", text)
text = re.sub(r"late final TextEditingController _portCtrl;\n", "", text)

# remove _brokerCtrl and _portCtrl from initState
text = re.sub(r"_brokerCtrl = TextEditingController.*?;\n", "", text)
text = re.sub(r"_portCtrl = TextEditingController.*?;\n", "", text)

# remove them from dispose
text = re.sub(r"_brokerCtrl,\n\s*_portCtrl,\n", "", text)

# remove _connect and _disconnect
connect_body = """  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    final mqttService = ref.read(mqttServiceProvider);
    final request = ref.read(mqttRequestProvider);
    await mqttService.connect(request);
    if (mounted) {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnect() async {
    await ref.read(mqttServiceProvider).disconnect();
  }\n\n"""
text = text.replace(connect_body, "")

# remove connState logic
text = re.sub(r"final isReconnecting = connState\?\.isReconnecting \?\? false;\n", "", text)
text = re.sub(r"final showLoading = _isConnecting \|\| isReconnecting;\n", "", text)

# remove brokerUrl listen
listen_block = """    ref.listen(mqttRequestProvider, (previous, next) {
      if (previous?.brokerUrl != next.brokerUrl &&
          _brokerCtrl.text != next.brokerUrl) {
        _brokerCtrl.text = next.brokerUrl;
      }
    });"""
text = text.replace(listen_block, "")

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'w') as f:
    f.write(text)

