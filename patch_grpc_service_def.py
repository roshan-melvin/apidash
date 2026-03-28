import re

with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_service_def.dart', 'r') as f:
    text = f.read()

text = text.replace(
"""    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref.watch(collectionStateNotifierProvider)?[selectedId];
    
    if (requestModel == null || requestModel.grpcRequestModel == null) {
      return const SizedBox.shrink();
    }

    final connectionState = requestModel.grpcConnectionState;""",
"""    final selectedId = ref.watch(selectedIdStateProvider);
    final requestModel = ref.watch(collectionStateNotifierProvider)?[selectedId];
    
    if (requestModel == null || requestModel.grpcRequestModel == null) {
      return const SizedBox.shrink();
    }

    final connectionStateAsync = ref.watch(grpcStateProvider);
    final connectionState = connectionStateAsync.value;""")

with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_service_def.dart', 'w') as f:
    f.write(text)

