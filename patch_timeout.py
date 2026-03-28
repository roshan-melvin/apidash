with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

text = text.replace(
'''      _channel = ClientChannel(
        host,
        port: port,
        options: ChannelOptions(credentials: requestModel.useTls ? const ChannelCredentials.secure() : const ChannelCredentials.insecure()),
      );

      await _channel!.getConnection();''',
'''      _channel = ClientChannel(
        host,
        port: port,
        options: ChannelOptions(
          credentials: requestModel.useTls ? const ChannelCredentials.secure() : const ChannelCredentials.insecure(),
          connectionTimeout: const Duration(seconds: 10),
        ),
      );

      await _channel!.getConnection().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timed out after 10 seconds. Check port and TLS settings.'),
      );'''
)

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)
