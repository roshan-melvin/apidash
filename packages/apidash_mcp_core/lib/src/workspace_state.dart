/// Shared in-memory workspace state.
///
/// The Flutter app writes into this singleton (via McpSyncService) after
/// every save / send-request cycle.  The MCP tool callbacks read from it.
/// Because both live in the **same Dart process** when the server is
/// embedded, no IPC is needed.
class WorkspaceState {
  // ------- singleton -----------------------------------------------
  static final WorkspaceState _instance = WorkspaceState._();
  factory WorkspaceState() => _instance;
  WorkspaceState._();

  // ------- state ----------------------------------------------------
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> environments = [];
  Map<String, dynamic>? lastResponse;
  String? selectedRequestId;
  /// Transient: which request to pre-select next time the Code Generator resource is fetched.
  String? pendingCodegenPreloadId;
  /// Transient: full request object to preload into the Request Builder.
  Map<String, dynamic>? pendingBuilderPreload;

  // ------- mutators -------------------------------------------------
  void updateRequests(List<Map<String, dynamic>> r) => requests = List.from(r);
  void updateEnvironments(List<Map<String, dynamic>> e) =>
      environments = List.from(e);
  void updateLastResponse(Map<String, dynamic> r) => lastResponse = r;
  void updateSelectedId(String? id) => selectedRequestId = id;

  /// Append a request queued by an MCP tool (e.g. save-request).
  /// The Flutter app polls [pendingRequests] on its next sync.
  final List<Map<String, dynamic>> pendingRequests = [];
  void queueRequest(Map<String, dynamic> req) => pendingRequests.add(req);
  List<Map<String, dynamic>> drainPending() {
    final copy = List<Map<String, dynamic>>.from(pendingRequests);
    pendingRequests.clear();
    return copy;
  }
}
