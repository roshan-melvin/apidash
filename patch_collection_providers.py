import sys

content = open('/home/rocroshan/Desktop/GSOC/apidash/lib/providers/collection_providers.dart', 'r').read()

patch = '''  void updateGrpcState({
    required String id,
    GrpcRequestModel? grpcRequestModel,
    GrpcConnectionState? grpcConnectionState,
    bool isManualEdit = true,
  }) {
    if (state == null || !state!.containsKey(id)) return;
    
    final currentModel = state![id]!;
    final newModel = currentModel.copyWith(
      grpcRequestModel: grpcRequestModel ?? currentModel.grpcRequestModel,
      grpcConnectionState: grpcConnectionState ?? currentModel.grpcConnectionState,
    );

    var map = {...state!};
    map[id] = newModel;
    state = map;

    if (isManualEdit) {
      unsave();
    }
  }

  void updateGrpcModel({
    String? id,
    String? host,
    int? port,
    bool? useTls,
    String? serviceName,
    String? methodName,
    GrpcCallType? callType,
    GrpcDescriptorSource? descriptorSource,
    List<NameValueModel>? metadata,
    List<bool>? isMetadataEnabledList,
    String? requestJson,
  }) {
    final rId = id ?? ref.read(selectedIdStateProvider);
    if (rId == null || state?[rId] == null) return;

    final currentModel = state![rId]!;
    final currentGrpcModel = currentModel.grpcRequestModel;
    
    if (currentGrpcModel == null) return;

    final updatedGrpcModel = currentGrpcModel.copyWith(
      host: host ?? currentGrpcModel.host,
      port: port ?? currentGrpcModel.port,
      useTls: useTls ?? currentGrpcModel.useTls,
      serviceName: serviceName ?? currentGrpcModel.serviceName,
      methodName: methodName ?? currentGrpcModel.methodName,
      callType: callType ?? currentGrpcModel.callType,
      descriptorSource: descriptorSource ?? currentGrpcModel.descriptorSource,
      metadata: metadata ?? currentGrpcModel.metadata,
      isMetadataEnabledList: isMetadataEnabledList ?? currentGrpcModel.isMetadataEnabledList,
      requestJson: requestJson ?? currentGrpcModel.requestJson,
    );

    updateGrpcState(
      id: rId,
      grpcRequestModel: updatedGrpcModel,
      isManualEdit: false,
    );
  }
'''

content = content.replace('void updateWebSocketState(', patch + '\n  void updateWebSocketState(')

imports_patch = '''import '../models/grpc_request_model.dart';
import '../services/grpc_service.dart';
'''

if 'import \'../models/grpc_request_model.dart\';' not in content:
    content = content.replace('import \'../models/websocket_request_model.dart\';', imports_patch + 'import \'../models/websocket_request_model.dart\';')

open('/home/rocroshan/Desktop/GSOC/apidash/lib/providers/collection_providers.dart', 'w').write(content)
