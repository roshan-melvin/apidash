// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mqtt_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MQTTRequestModel _$MQTTRequestModelFromJson(Map<String, dynamic> json) =>
    _MQTTRequestModel(
      brokerUrl: json['brokerUrl'] as String? ?? "",
      port: (json['port'] as num?)?.toInt() ?? 1883,
      clientId: json['clientId'] as String? ?? "",
      username: json['username'] as String? ?? "",
      password: json['password'] as String? ?? "",
      keepAlive: (json['keepAlive'] as num?)?.toInt() ?? 60,
      cleanSession: json['cleanSession'] as bool? ?? false,
      connectTimeout: (json['connectTimeout'] as num?)?.toInt() ?? 3,
      topics:
          (json['topics'] as List<dynamic>?)
              ?.map((e) => MQTTTopicModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      publishTopic: json['publishTopic'] as String? ?? "",
      publishPayload: json['publishPayload'] as String? ?? "",
      publishQos: (json['publishQos'] as num?)?.toInt() ?? 0,
      publishRetain: json['publishRetain'] as bool? ?? false,
    );

Map<String, dynamic> _$MQTTRequestModelToJson(_MQTTRequestModel instance) =>
    <String, dynamic>{
      'brokerUrl': instance.brokerUrl,
      'port': instance.port,
      'clientId': instance.clientId,
      'username': instance.username,
      'password': instance.password,
      'keepAlive': instance.keepAlive,
      'cleanSession': instance.cleanSession,
      'connectTimeout': instance.connectTimeout,
      'topics': instance.topics,
      'publishTopic': instance.publishTopic,
      'publishPayload': instance.publishPayload,
      'publishQos': instance.publishQos,
      'publishRetain': instance.publishRetain,
    };

_MQTTTopicModel _$MQTTTopicModelFromJson(Map<String, dynamic> json) =>
    _MQTTTopicModel(
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
