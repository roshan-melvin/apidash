import 'package:grpc/grpc.dart';
import 'package:apidash/services/grpc_reflection_service.dart';

void main() async {
  final channel = ClientChannel(
    '1.2.3.4',
    port: 9001,
    options: const ChannelOptions(
      connectionTimeout: Duration(seconds: 2),
      credentials: ChannelCredentials.insecure(),
    ),
  );
  try {
    print('Connecting...');
    final r = GrpcReflectionService();
    final d = await r.loadDescriptorsViaReflection(channel: channel, host: '1.2.3.4').timeout(Duration(seconds: 2), onTimeout: () {
      throw Exception('Reflection timeout');
    });
    print('Connected');
  } catch (e) {
    print('Error: $e');
  }
}
