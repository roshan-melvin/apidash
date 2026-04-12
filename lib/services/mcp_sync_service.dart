import 'package:apidash/models/models.dart';
import 'package:apidash_mcp_core/apidash_mcp_core.dart';

/// Bridges the Flutter Riverpod state into the in-process [WorkspaceState]
/// singleton used by MCP tool callbacks.
///
/// Called from [CollectionStateNotifier.saveData] (already wired) and
/// from [EnvironmentsStateNotifier] (see environment_providers.dart).
class McpSyncService {
  /// Push the current list of [RequestModel]s into [WorkspaceState].
  static Future<void> syncWorkspaceToMcp(
    List<RequestModel>? requests,
    List<dynamic>? environments,
  ) async {
    try {
      final store = WorkspaceState();

      if (requests != null) {
        store.updateRequests(
          requests.map((r) {
            return <String, dynamic>{
              'id': r.id,
              'name': r.name,
              'method': r.httpRequestModel?.method.name.toUpperCase() ?? 'GET',
              'url': r.httpRequestModel?.url ?? '',
              'headers': r.httpRequestModel?.enabledHeadersMap ?? <String, String>{},
              'body': r.httpRequestModel?.body,
              'responseStatus': r.responseStatus,
              'responseBody': r.httpResponseModel?.body,
              'isWorking': r.isWorking,
            };
          }).toList(),
        );

        // Keep lastResponse up-to-date
        final last = requests
            .where((r) => r.httpResponseModel != null)
            .lastOrNull;
        if (last != null) {
          store.updateLastResponse(<String, dynamic>{
            'id': last.id,
            'name': last.name,
            'responseStatus': last.responseStatus,
            'body': last.httpResponseModel?.body,
            'headers': last.httpResponseModel?.headers,
            'duration': last.httpResponseModel?.time?.inMilliseconds,
          });
        }
      }

      if (environments != null) {
        // environments is List<EnvironmentModel> serialised as Map
        store.updateEnvironments(
          environments
              .map((e) {
                if (e is Map<String, dynamic>) return e;
                // Attempt toJson() if it is an EnvironmentModel
                try {
                  return (e as dynamic).toJson() as Map<String, dynamic>;
                } catch (_) {
                  return <String, dynamic>{'raw': e.toString()};
                }
              })
              .toList()
              .cast<Map<String, dynamic>>(),
        );
      }
    } catch (e) {
      // Never throw — this is a best-effort bridge.
      // ignore: avoid_print
      print('[McpSyncService] sync failed: $e');
    }
  }

  /// Drain any requests queued by MCP tools (e.g. save-request) so the
  /// Flutter app can inject them into Riverpod state.
  static List<Map<String, dynamic>> drainPendingMcpRequests() {
    return WorkspaceState().drainPending();
  }
}
