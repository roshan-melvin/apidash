import 'package:grpc/grpc.dart';
import 'package:apidash/services/grpc_reflection_service.dart';

Future<void> main() async {
  final channel = ClientChannel(
    'grpcb.in',
    port: 9001,
    options: ChannelOptions(
      credentials: ChannelCredentials.secure(),
      connectionTimeout: Duration(seconds: 15),
    ),
  );
  try {
    print('Connecting...');
    final conn = await channel.getConnection().timeout(Duration(seconds: 15));
    print('Connected via TCP. Triggering reflection...');
    final r = GrpcReflectionService();
    try {
      final t = DateTime.now();
      final d = await r
          .loadDescriptorsViaReflection(channel: channel, host: 'grpcb.in')
          .timeout(Duration(seconds: 15));
      print('len: ${d.length}');
      print('time took: ${DateTime.now().difference(t).inMilliseconds}ms');
    } catch (e) {
      print('Reflection failed: $e');
    }
  } catch (e) {
    print('Error: $e');
  }
}
