import 'package:mcp_dart/mcp_dart.dart';

Future<StreamableHTTPServerTransport> setupRequestRouter(McpServer server) async {
  final transport = StreamableHTTPServerTransport(
    options: StreamableHTTPServerTransportOptions(
      sessionIdGenerator: () => 'session-${DateTime.now().millisecondsSinceEpoch}',
      eventStore: InMemoryEventStore(),
      enableDnsRebindingProtection: false,
      strictProtocolVersionHeaderValidation: false,
      rejectBatchJsonRpcPayloads: false,
    ),
  );
  
  await server.connect(transport);
  return transport;
}

