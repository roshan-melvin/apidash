import 'package:freezed_annotation/freezed_annotation.dart';

part 'mqtt_request_model.freezed.dart';
part 'mqtt_request_model.g.dart';

enum MQTTProtocolVersion {
  v31,
  v311,
  v5,
}

@freezed
abstract class MQTTRequestModel with _$MQTTRequestModel {
  @JsonSerializable(explicitToJson: true, anyMap: true)
  const factory MQTTRequestModel({
    @Default("") String brokerUrl,
    @Default(1883) int port,
    @Default("") String clientId,
    @Default("") String username,
    @Default("") String password,
    @Default(60) int keepAlive,
    @Default(false) bool cleanSession,
    @Default(3) int connectTimeout,
    @Default(MQTTProtocolVersion.v311) MQTTProtocolVersion protocolVersion,
    @Default(false) bool useTls,
    @Default([]) List<MQTTTopicModel> topics,
    @Default("") String publishTopic,
    @Default("") String publishPayload,
    @Default(0) int publishQos,
    @Default(false) bool publishRetain,
    @Default("") String lastWillTopic,
    @Default("") String lastWillMessage,
    @Default(0) int lastWillQos,
    @Default(false) bool lastWillRetain,
    @Default([]) List<MQTTSavedMessage> savedMessages,
    @Default([]) List<MQTTSavedEvent> savedEventLog,
  }) = _MQTTRequestModel;

  factory MQTTRequestModel.fromJson(Map<String, Object?> json) =>
      _$MQTTRequestModelFromJson(json);
}

@freezed
abstract class MQTTTopicModel with _$MQTTTopicModel {
  @JsonSerializable(explicitToJson: true, anyMap: true)
  const factory MQTTTopicModel({
    required String topic,
    @Default(0) int qos,
    @Default(false) bool subscribe,
    @Default("") String description,
  }) = _MQTTTopicModel;

  factory MQTTTopicModel.fromJson(Map<String, Object?> json) =>
      _$MQTTTopicModelFromJson(json);
}

/// Persistent snapshot of a single MQTT message (IN or OUT).
@freezed
abstract class MQTTSavedMessage with _$MQTTSavedMessage {
  @JsonSerializable(anyMap: true)
  const factory MQTTSavedMessage({
    required String topic,
    required String payload,
    required DateTime timestamp,
    required bool isIncoming,
  }) = _MQTTSavedMessage;

  factory MQTTSavedMessage.fromJson(Map<String, Object?> json) =>
      _$MQTTSavedMessageFromJson(json);
}

/// Persistent snapshot of a single MQTT event log entry.
@freezed
abstract class MQTTSavedEvent with _$MQTTSavedEvent {
  @JsonSerializable(anyMap: true)
  const factory MQTTSavedEvent({
    required DateTime timestamp,
    required String eventType,
    required String description,
    String? topic,
    String? payload,
  }) = _MQTTSavedEvent;

  factory MQTTSavedEvent.fromJson(Map<String, Object?> json) =>
      _$MQTTSavedEventFromJson(json);
}

const kMQTTRequestEmptyModel = MQTTRequestModel();
const kMQTTTopicEmptyModel = MQTTTopicModel(topic: "");
