import 'package:grpc/grpc.dart';
import 'package:apidash/services/grpc_reflection_service.dart';

Future<void> main() async {
  final channel = ClientChannel(
    'grpcb.in',
    port: 9001,
    options: ChannelOptions(credentials: ChannelCredentials.secure()),
  );
  try {
    print('Connecting...');
    final r = GrpcReflectionService();
    final d = await r.loadDescriptorsViaReflection(
      channel: channel,
      host: 'grpcb.in',
    );
    print('Connected! length=${d.length}');
  } catch (e) {
    print('Error: $e');
  }
}
