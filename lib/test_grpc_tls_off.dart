import 'package:grpc/grpc.dart';
import 'package:apidash/services/grpc_reflection_service.dart';

Future<void> main() async {
  final channel = ClientChannel(
    'grpcb.in',
    port: 9001,
    options: ChannelOptions(
      credentials: ChannelCredentials.insecure(),
      connectionTimeout: Duration(seconds: 15),
    ),
  );
  try {
    print('Connecting...');
    final t1 = DateTime.now();
    final conn = await channel.getConnection().timeout(Duration(seconds: 15));
    print('Connected via TCP in \${DateTime.now().difference(t1).inMilliseconds}ms. Triggering reflection...');
    final r = GrpcReflectionService();
    try {
      final t2 = DateTime.now();
      final d = await r.loadDescriptorsViaReflection(channel: channel, host: 'grpcb.in').timeout(Duration(seconds: 15));
      print('len: \${d.length}');
    } catch (e) {
      print('Reflection failed after \${DateTime.now().difference(t2).inMilliseconds}ms: \$e');
    }
  } catch (e) {
    print('Error: \$e');
  }
}
