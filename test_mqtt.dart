import 'package:mqtt_client/mqtt_client.dart' as mqtt3;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt3_server;

void main() async {
  final client = mqtt3_server.MqttServerClient('broker.emqx.io', 'test_apidash_123');
  client.port = 1883;
  client.logging(on: true);
  client.connectTimeoutPeriod = 4000;
  try {
    await client.connect();
    print('Connected to EMQX');
    client.disconnect();
  } catch (e) {
    print('Exception: $e');
  }
}
