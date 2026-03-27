import 'package:apidash_core/apidash_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/mqtt_request_model.dart';
import '../services/mqtt_service.dart';
import 'collection_providers.dart';

/// Single MQTT service instance for the app lifetime.
final mqttServiceProvider = Provider<MQTTService>((ref) {
  final service = MQTTService();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream of live connection state (connected, messages, event log).
final mqttConnectionStateProvider =
    StreamProvider<MQTTConnectionState>((ref) {
  return ref.watch(mqttServiceProvider).stateStream;
});

/// The current MQTT request config being edited.
final mqttRequestProvider = StateProvider<MQTTRequestModel>((ref) {
  final selectedId = ref.watch(selectedIdStateProvider);
  if (selectedId != null) {
    final model = ref.watch(collectionStateNotifierProvider)?[selectedId];
    if (model != null && model.apiType == APIType.mqtt) {
      return model.mqttRequestModel ?? kMQTTRequestEmptyModel;
    }
  }
  return kMQTTRequestEmptyModel;
});

/// Derived list of topics from the active request.
final mqttTopicsProvider = Provider<List<MQTTTopicModel>>((ref) {
  return ref.watch(mqttRequestProvider).topics;
});

/// Messages for the current session — falls back to saved messages when disconnected.
final mqttMessagesProvider = Provider<List<MQTTMessage>>((ref) {
  final liveState = ref.watch(mqttConnectionStateProvider);
  final liveMessages = liveState.value?.messages;

  // If the live stream has messages, use them
  if (liveMessages != null && liveMessages.isNotEmpty) {
    return liveMessages;
  }

  // Otherwise fall back to the last saved messages from Hive
  final saved = ref.watch(mqttRequestProvider).savedMessages;
  return saved
      .map((s) => MQTTMessage(
            topic: s.topic,
            payload: s.payload,
            timestamp: s.timestamp,
            isIncoming: s.isIncoming,
          ))
      .toList();
});

/// Event log for the current session — falls back to saved events when disconnected.
final mqttEventLogProvider = Provider<List<MQTTEvent>>((ref) {
  final liveState = ref.watch(mqttConnectionStateProvider);
  final liveEvents = liveState.value?.eventLog;

  // If the live stream has events, use them
  if (liveEvents != null && liveEvents.isNotEmpty) {
    return liveEvents;
  }

  // Otherwise fall back to the last saved event log from Hive
  final saved = ref.watch(mqttRequestProvider).savedEventLog;
  return saved
      .map((e) => MQTTEvent(
            timestamp: e.timestamp,
            type: MQTTEventType.values.firstWhere(
              (t) => t.name == e.eventType,
              orElse: () => MQTTEventType.connect,
            ),
            topic: e.topic,
            payload: e.payload,
            description: e.description,
          ))
      .toList();
});

/// Syncs MQTT connection state back into the RequestModel collection
/// so the sidebar badge, messages, and event log survive app restarts.
final mqttStateSyncProvider = Provider<void>((ref) {
  final selectedId = ref.watch(selectedIdStateProvider);
  final notifier =
      ref.watch(collectionStateNotifierProvider.notifier);

  ref.listen(mqttConnectionStateProvider, (_, next) {
    if (next.hasValue && selectedId != null) {
      final model = ref
          .read(collectionStateNotifierProvider)
          ?[selectedId];
      if (model != null && model.apiType == APIType.mqtt) {
        // Convert live MQTTMessage -> MQTTSavedMessage for persistence
        final savedMsgs = next.value!.messages
            .map((m) => MQTTSavedMessage(
                  topic: m.topic,
                  payload: m.payload,
                  timestamp: m.timestamp,
                  isIncoming: m.isIncoming,
                ))
            .toList();

        // Convert live MQTTEvent -> MQTTSavedEvent for persistence
        final savedEvents = next.value!.eventLog
            .map((e) => MQTTSavedEvent(
                  timestamp: e.timestamp,
                  eventType: e.type.name,
                  description: e.description,
                  topic: e.topic,
                  payload: e.payload,
                ))
            .toList();

        final updatedMqtt = (model.mqttRequestModel ?? kMQTTRequestEmptyModel)
            .copyWith(
          savedMessages: savedMsgs,
          savedEventLog: savedEvents,
        );

        notifier.updateMQTTState(
          id: selectedId,
          mqttRequestModel: updatedMqtt,
          mqttConnectionState: next.value,
          isManualEdit: false,
        );
        notifier.saveRequestModel(selectedId);
      }
    }
  });
});
