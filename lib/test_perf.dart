import 'package:grpc/grpc.dart';
import 'package:apidash/services/grpc_reflection_service.dart';

Future<void> test(bool secure) async {
  final s = Stopwatch()..start();
  final channel = ClientChannel(
    'grpcb.in',
    port: 9001,
    options: ChannelOptions(
      credentials: secure
          ? ChannelCredentials.secure()
          : ChannelCredentials.insecure(),
      connectionTimeout: Duration(seconds: 15),
    ),
  );
  try {
    print('Connecting secure=$secure...');
    final conn = await channel.getConnection().timeout(Duration(seconds: 15));
    print('TCP in ' + s.elapsedMilliseconds.toString() + 'ms');
    s.reset();
    final r = GrpcReflectionService();
    await r
        .loadDescriptorsViaReflection(channel: channel, host: 'grpcb.in')
        .timeout(Duration(seconds: 15));
    print('Reflection in ' + s.elapsedMilliseconds.toString() + 'ms');
  } catch (e) {
    print(
      'Failed after ' +
          s.elapsedMilliseconds.toString() +
          'ms: ' +
          e.toString(),
    );
  }
}

Future<void> main() async {
  await test(true);
  print('=================');
  await test(false);
}
