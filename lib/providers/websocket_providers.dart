import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/websocket_service.dart';
import 'package:apidash_core/apidash_core.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'collection_providers.dart';

// 1. The Global Service Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

// 2. The Auto-Dispose Stream Provider for live Socket State
final webSocketStateProvider = StreamProvider.autoDispose<WebSocketConnectionState>((ref) {
  return ref.watch(webSocketServiceProvider).stateStream;
});

// The current WebSocket request config being edited.
final webSocketRequestProvider = StateProvider<WebSocketRequestModel>((ref) {
  final selectedId = ref.watch(selectedIdStateProvider);
  if (selectedId != null) {
    final model = ref.watch(collectionStateNotifierProvider)?[selectedId];
    if (model != null && model.apiType == APIType.websocket) {
      return model.websocketRequestModel ?? kWebSocketRequestEmptyModel;
    }
  }
  return kWebSocketRequestEmptyModel;
});


// 3. Fallback Providers (Provides live data if connected, or persisted Hive data if offline)
final webSocketMessagesProvider = Provider.autoDispose.family<List<WebSocketMessage>, String>((ref, id) {
  final liveStateAsync = ref.watch(webSocketStateProvider);
  final liveMessages = liveStateAsync.value?.messages;
  
  if (liveMessages != null && liveMessages.isNotEmpty) {
    return liveMessages;
  }
  
  final saved = ref.watch(webSocketRequestProvider).savedMessages;
  return saved.map((e) => WebSocketMessage(
        payload: e.payload,
        isText: e.isText,
        timestamp: e.timestamp,
        isIncoming: e.isIncoming,
      )).toList();
});

final webSocketEventLogProvider = Provider.autoDispose.family<List<WebSocketEvent>, String>((ref, id) {
  final liveStateAsync = ref.watch(webSocketStateProvider);
  final liveEvents = liveStateAsync.value?.eventLog;
  
  if (liveEvents != null && liveEvents.isNotEmpty) {
    return liveEvents;
  }
  
  final saved = ref.watch(webSocketRequestProvider).savedEventLog;
  return saved.map((e) => WebSocketEvent(
        timestamp: e.timestamp,
        type: WebSocketEventType.values.firstWhere(
            (x) => x.name == e.eventType,
            orElse: () => WebSocketEventType.connect),
        description: e.description,
      )).toList();
});

// 4. Background Persistence Engine (The "Quiet" Sync)
final webSocketStateSyncProvider = Provider<void>((ref) {
  final selectedId = ref.watch(selectedIdStateProvider);
  final notifier = ref.watch(collectionStateNotifierProvider.notifier);

  ref.listen(webSocketStateProvider, (_, next) {
    if (next.hasValue && selectedId != null) {
      final model = ref.read(collectionStateNotifierProvider)?[selectedId];
      if (model != null && model.apiType == APIType.websocket) {
      
        final savedMessages = next.value!.messages.map((m) => WebSocketSavedMessage(
          payload: m.payload.toString(),
          isText: m.isText,
          timestamp: m.timestamp,
          isIncoming: m.isIncoming,
        )).toList();

        final savedEvents = next.value!.eventLog.map((e) => WebSocketSavedEvent(
          timestamp: e.timestamp,
          eventType: e.type.name,
          description: e.description,
        )).toList();

        final updatedWs = (model.websocketRequestModel ?? kWebSocketRequestEmptyModel).copyWith(
          savedMessages: savedMessages,
          savedEventLog: savedEvents,
        );

        notifier.updateWebSocketState(
          id: selectedId,
          websocketRequestModel: updatedWs,
          websocketConnectionState: next.value,
          isManualEdit: false,
        );
        notifier.saveRequestModel(selectedId);
      }
    }
  });
});
