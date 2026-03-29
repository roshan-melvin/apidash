import 'package:grpc/grpc.dart';
import 'package:apidash/services/grpc_reflection_service.dart';

Future<void> main() async {
  final channel = ClientChannel(
    'grpcb.in',
    port: 9001,
    options: ChannelOptions(
      credentials: ChannelCredentials.insecure(),
      connectionTimeout: Duration(seconds: 4),
    ),
  );
  try {
    print('Connecting insecurely to secure port...');
    final conn = await channel.getConnection().timeout(Duration(seconds: 4));
    print('TCP Connection successful. Assuming it got stuck after this.');

    // Now trigger reflection.
    final r = GrpcReflectionService();
    try {
      final t = DateTime.now();
      final d = await r
          .loadDescriptorsViaReflection(channel: channel, host: 'grpcb.in')
          .timeout(Duration(seconds: 4));
      print('len: \${d.length}');
    } catch (e) {
      print('Reflection failed: \$e');
    }
  } catch (e) {
    print('Error: \$e');
  }
}
