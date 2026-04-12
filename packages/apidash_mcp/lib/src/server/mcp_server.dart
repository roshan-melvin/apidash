import 'package:mcp_dart/mcp_dart.dart';
import '../tools/tools_registry.dart';
import '../resources/resources_registry.dart';

McpServer createMcpServer() {
  final server = McpServer(
    Implementation(name: 'apidash-mcp', version: '1.0.0'),
    options: ServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
        resources: ServerCapabilitiesResources(),
      ),
    ),
  );
  registerTools(server);
  ResourcesRegistry.registerAll(server);
  return server;
}
