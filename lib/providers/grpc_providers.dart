import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/grpc_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:apidash_core/apidash_core.dart';
import 'collection_providers.dart';

final grpcServiceProvider = Provider<GrpcService>((ref) {
  final service = GrpcService();
  ref.onDispose(() => service.dispose());
  return service;
});

final grpcStateProvider = StreamProvider.autoDispose<GrpcConnectionState>((
  ref,
) async* {
  final service = ref.watch(grpcServiceProvider);
  yield service.currentState;
  yield* service.stateStream;
});

final grpcRequestProvider = StateProvider<GrpcRequestModel>((ref) {
  final selectedId = ref.watch(selectedIdStateProvider);
  if (selectedId != null) {
    final model = ref.watch(collectionStateNotifierProvider)?[selectedId];
    if (model != null && model.apiType == APIType.grpc) {
      return model.grpcRequestModel ?? const GrpcRequestModel();
    }
  }
  return const GrpcRequestModel();
});

final grpcMessagesProvider = Provider.autoDispose
    .family<List<GrpcMessage>, String>((ref, id) {
      final liveStateAsync = ref.watch(grpcStateProvider);
      final liveMessages = liveStateAsync.value?.messages;

      if (liveMessages != null && liveMessages.isNotEmpty) {
        return liveMessages;
      }

      return [];
    });

final grpcEventLogProvider = Provider.autoDispose
    .family<List<GrpcEvent>, String>((ref, id) {
      final liveStateAsync = ref.watch(grpcStateProvider);
      final liveEventLog = liveStateAsync.value?.eventLog;

      if (liveEventLog != null && liveEventLog.isNotEmpty) {
        return liveEventLog;
      }

      return [];
    });
