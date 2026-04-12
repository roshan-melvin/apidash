import 'package:mcp_dart/mcp_dart.dart';

import 'request_builder_resource.dart';
import 'response_viewer_resource.dart';
import 'collections_explorer_resource.dart';
import 'graphql_explorer_resource.dart';
import 'code_generator_resource.dart';
import 'env_manager_resource.dart';
import 'code_viewer_resource.dart';

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
