// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WebSocketSavedMessage _$WebSocketSavedMessageFromJson(Map json) =>
    _WebSocketSavedMessage(
      payload: json['payload'] as String,
      isText: json['isText'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isIncoming: json['isIncoming'] as bool,
    );

Map<String, dynamic> _$WebSocketSavedMessageToJson(
  _WebSocketSavedMessage instance,
) => <String, dynamic>{
  'payload': instance.payload,
  'isText': instance.isText,
  'timestamp': instance.timestamp.toIso8601String(),
  'isIncoming': instance.isIncoming,
};

_WebSocketSavedEvent _$WebSocketSavedEventFromJson(Map json) =>
    _WebSocketSavedEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventType: json['eventType'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$WebSocketSavedEventToJson(
  _WebSocketSavedEvent instance,
) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
  'eventType': instance.eventType,
  'description': instance.description,
};

_WebSocketRequestModel _$WebSocketRequestModelFromJson(Map json) =>
    _WebSocketRequestModel(
      url: json['url'] as String? ?? "",
      requestHeaders: (json['requestHeaders'] as List<dynamic>?)
          ?.map(
            (e) => NameValueModel.fromJson(Map<String, Object?>.from(e as Map)),
          )
          .toList(),
      isHeaderEnabledList: (json['isHeaderEnabledList'] as List<dynamic>?)
          ?.map((e) => e as bool)
          .toList(),
      savedMessages:
          (json['savedMessages'] as List<dynamic>?)
              ?.map(
                (e) => WebSocketSavedMessage.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
      savedEventLog:
          (json['savedEventLog'] as List<dynamic>?)
              ?.map(
                (e) => WebSocketSavedEvent.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
      requestTabIndex: (json['requestTabIndex'] as num?)?.toInt() ?? 0,
      filterIndex: (json['filterIndex'] as num?)?.toInt() ?? 0,
      pingInterval: (json['pingInterval'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WebSocketRequestModelToJson(
  _WebSocketRequestModel instance,
) => <String, dynamic>{
  'url': instance.url,
  'requestHeaders': instance.requestHeaders?.map((e) => e.toJson()).toList(),
  'isHeaderEnabledList': instance.isHeaderEnabledList,
  'savedMessages': instance.savedMessages.map((e) => e.toJson()).toList(),
  'savedEventLog': instance.savedEventLog.map((e) => e.toJson()).toList(),
  'requestTabIndex': instance.requestTabIndex,
  'filterIndex': instance.filterIndex,
  'pingInterval': instance.pingInterval,
};
