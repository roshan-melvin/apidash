import 'package:mcp_dart/mcp_dart.dart';

import 'impl/request_builder.dart';
import 'impl/http_send_request.dart';
import 'impl/view_response.dart';
import 'impl/explore_collections.dart';
import 'impl/graphql_explorer.dart';
import 'impl/graphql_execute_query.dart';
import 'impl/codegen_ui.dart';
import 'impl/generate_code_snippet.dart';
import 'impl/manage_environment.dart';
import 'impl/update_environment_variables.dart';
import 'impl/get_api_request_template.dart';
import 'impl/ai_llm_request.dart';
import 'impl/save_request.dart';
import 'impl/get_last_response.dart';

void registerTools(McpServer server) {
  registerRequestBuilder(server);
  registerHttpSendRequest(server);
  registerViewResponse(server);
  registerExploreCollections(server);
  registerGraphqlExplorer(server);
  registerGraphqlExecuteQuery(server);
  registerCodegenUi(server);
  registerGenerateCodeSnippet(server);
  registerManageEnvironment(server);
  registerUpdateEnvironmentVariables(server);
  registerGetApiRequestTemplate(server);
  registerAiLlmRequest(server);
  registerSaveRequest(server);
  registerGetLastResponse(server);
}