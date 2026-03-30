import 'dart:io';
void main() async {
  print('connecting...');
  try {
    final s = await Socket.connect('test.mosquitto.org', 1883, timeout: Duration(seconds: 3));
    print('Connected');
    s.destroy();
  } catch (e) {
    print('Failed: $e');
  }
}
