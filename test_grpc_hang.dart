import 'package:grpc/grpc.dart';
import 'package:apidash/services/grpc_reflection_service.dart';

Future<void> main() async {
  final channel = ClientChannel(
    'grpcb.in',
    port: 9001,
    options: ChannelOptions(
      credentials: ChannelCredentials.insecure(),
      connectionTimeout: Duration(seconds: 5),
    ),
  );
  try {
    print('Connecting...');
    await channel.getConnection().timeout(Duration(seconds: 5), onTimeout: () { throw Exception('timeout 1'); });
    print('Connected! Now reflection...');
    final r = GrpcReflectionService();
    final d = await r.loadDescriptorsViaReflection(channel: channel, host: 'grpcb.in').timeout(Duration(seconds: 5), onTimeout: () { throw Exception('timeout 2'); });
    print('Reflection done');
  } catch (e) {
    print('Error: $e');
  }
}
