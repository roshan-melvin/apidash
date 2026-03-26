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

/// Messages received/sent in the current session.
final mqttMessagesProvider = Provider<List<MQTTMessage>>((ref) {
  final state = ref.watch(mqttConnectionStateProvider);
  return state.value?.messages ?? [];
});

/// Event log for the current session.
final mqttEventLogProvider = Provider<List<MQTTEvent>>((ref) {
  final state = ref.watch(mqttConnectionStateProvider);
  return state.value?.eventLog ?? [];
});

/// Syncs MQTT connection state back into the RequestModel collection
/// so the sidebar badge and history work correctly.
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
        notifier.updateMQTTState(
          id: selectedId,
          mqttConnectionState: next.value,
        );
      }
    }
  });
});
