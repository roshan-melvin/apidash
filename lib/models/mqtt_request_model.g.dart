// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mqtt_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MQTTRequestModel _$MQTTRequestModelFromJson(Map json) => _MQTTRequestModel(
  brokerUrl: json['brokerUrl'] as String? ?? "",
  port: (json['port'] as num?)?.toInt() ?? 1883,
  clientId: json['clientId'] as String? ?? "",
  username: json['username'] as String? ?? "",
  password: json['password'] as String? ?? "",
  keepAlive: (json['keepAlive'] as num?)?.toInt() ?? 60,
  cleanSession: json['cleanSession'] as bool? ?? false,
  connectTimeout: (json['connectTimeout'] as num?)?.toInt() ?? 3,
  autoReconnect: json['autoReconnect'] as bool? ?? true,
  protocolVersion:
      $enumDecodeNullable(
        _$MQTTProtocolVersionEnumMap,
        json['protocolVersion'],
      ) ??
      MQTTProtocolVersion.v311,
  useTls: json['useTls'] as bool? ?? false,
  topics:
      (json['topics'] as List<dynamic>?)
          ?.map(
            (e) => MQTTTopicModel.fromJson(Map<String, Object?>.from(e as Map)),
          )
          .toList() ??
      const [],
  publishTopic: json['publishTopic'] as String? ?? "",
  publishPayload: json['publishPayload'] as String? ?? "",
  publishQos: (json['publishQos'] as num?)?.toInt() ?? 0,
  publishRetain: json['publishRetain'] as bool? ?? false,
  lastWillTopic: json['lastWillTopic'] as String? ?? "",
  lastWillMessage: json['lastWillMessage'] as String? ?? "",
  lastWillQos: (json['lastWillQos'] as num?)?.toInt() ?? 0,
  lastWillRetain: json['lastWillRetain'] as bool? ?? false,
  savedMessages:
      (json['savedMessages'] as List<dynamic>?)
          ?.map(
            (e) =>
                MQTTSavedMessage.fromJson(Map<String, Object?>.from(e as Map)),
          )
          .toList() ??
      const [],
  savedEventLog:
      (json['savedEventLog'] as List<dynamic>?)
          ?.map(
            (e) => MQTTSavedEvent.fromJson(Map<String, Object?>.from(e as Map)),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$MQTTRequestModelToJson(
  _MQTTRequestModel instance,
) => <String, dynamic>{
  'brokerUrl': instance.brokerUrl,
  'port': instance.port,
  'clientId': instance.clientId,
  'username': instance.username,
  'password': instance.password,
  'keepAlive': instance.keepAlive,
  'cleanSession': instance.cleanSession,
  'connectTimeout': instance.connectTimeout,
  'autoReconnect': instance.autoReconnect,
  'protocolVersion': _$MQTTProtocolVersionEnumMap[instance.protocolVersion]!,
  'useTls': instance.useTls,
  'topics': instance.topics.map((e) => e.toJson()).toList(),
  'publishTopic': instance.publishTopic,
  'publishPayload': instance.publishPayload,
  'publishQos': instance.publishQos,
  'publishRetain': instance.publishRetain,
  'lastWillTopic': instance.lastWillTopic,
  'lastWillMessage': instance.lastWillMessage,
  'lastWillQos': instance.lastWillQos,
  'lastWillRetain': instance.lastWillRetain,
  'savedMessages': instance.savedMessages.map((e) => e.toJson()).toList(),
  'savedEventLog': instance.savedEventLog.map((e) => e.toJson()).toList(),
};

const _$MQTTProtocolVersionEnumMap = {
  MQTTProtocolVersion.v31: 'v31',
  MQTTProtocolVersion.v311: 'v311',
  MQTTProtocolVersion.v5: 'v5',
};

_MQTTTopicModel _$MQTTTopicModelFromJson(Map json) => _MQTTTopicModel(
  topic: json['topic'] as String,
  qos: (json['qos'] as num?)?.toInt() ?? 0,
  subscribe: json['subscribe'] as bool? ?? false,
  description: json['description'] as String? ?? "",
);

Map<String, dynamic> _$MQTTTopicModelToJson(_MQTTTopicModel instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'qos': instance.qos,
      'subscribe': instance.subscribe,
      'description': instance.description,
    };

_MQTTSavedMessage _$MQTTSavedMessageFromJson(Map json) => _MQTTSavedMessage(
  topic: json['topic'] as String,
  payload: json['payload'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  isIncoming: json['isIncoming'] as bool,
  qos: (json['qos'] as num?)?.toInt() ?? 0,
  isRetained: json['isRetained'] as bool? ?? false,
);

Map<String, dynamic> _$MQTTSavedMessageToJson(_MQTTSavedMessage instance) =>
    <String, dynamic>{
      'topic': instance.topic,
      'payload': instance.payload,
      'timestamp': instance.timestamp.toIso8601String(),
      'isIncoming': instance.isIncoming,
      'qos': instance.qos,
      'isRetained': instance.isRetained,
    };

_MQTTSavedEvent _$MQTTSavedEventFromJson(Map json) => _MQTTSavedEvent(
  timestamp: DateTime.parse(json['timestamp'] as String),
  eventType: json['eventType'] as String,
  description: json['description'] as String,
  topic: json['topic'] as String?,
  payload: json['payload'] as String?,
);

Map<String, dynamic> _$MQTTSavedEventToJson(_MQTTSavedEvent instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'eventType': instance.eventType,
      'description': instance.description,
      'topic': instance.topic,
      'payload': instance.payload,
    };
