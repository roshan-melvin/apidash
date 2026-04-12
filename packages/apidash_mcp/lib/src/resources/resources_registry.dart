import 'package:mcp_dart/mcp_dart.dart';
import 'resources_impl.dart';

class ResourcesRegistry {
  static void registerAll(McpServer server) {
    registerRequestBuilderResource(server);
    registerResponseViewerResource(server);
    registerCollectionsExplorerResource(server);
    registerGraphqlExplorerResource(server);
    registerCodeGeneratorResource(server);
    registerEnvManagerResource(server);
    registerCodeViewerResource(server);
  }
}
