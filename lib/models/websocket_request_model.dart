import 'package:apidash_core/apidash_core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_request_model.freezed.dart';
part 'websocket_request_model.g.dart';

@freezed
abstract class WebSocketSavedMessage with _$WebSocketSavedMessage {
  @JsonSerializable(explicitToJson: true, anyMap: true)
  const factory WebSocketSavedMessage({
    required String payload,
    required bool isText,
    required DateTime timestamp,
    required bool isIncoming,
  }) = _WebSocketSavedMessage;

  factory WebSocketSavedMessage.fromJson(Map<String, dynamic> json) =>
      _$WebSocketSavedMessageFromJson(json);
}

@freezed
abstract class WebSocketSavedEvent with _$WebSocketSavedEvent {
  @JsonSerializable(explicitToJson: true, anyMap: true)
  const factory WebSocketSavedEvent({
    required DateTime timestamp,
    required String eventType,
    required String description,
  }) = _WebSocketSavedEvent;

  factory WebSocketSavedEvent.fromJson(Map<String, dynamic> json) =>
      _$WebSocketSavedEventFromJson(json);
}

@freezed
abstract class WebSocketRequestModel with _$WebSocketRequestModel {
  @JsonSerializable(explicitToJson: true, anyMap: true)
  const factory WebSocketRequestModel({
    @Default("") String url,
    List<NameValueModel>? requestParams,
    List<bool>? isParamEnabledList,
    List<NameValueModel>? requestHeaders,
    List<bool>? isHeaderEnabledList,
    @Default([]) List<WebSocketSavedMessage> savedMessages,
    @Default([]) List<WebSocketSavedEvent> savedEventLog,
    @Default(0) int requestTabIndex,
    @Default(0) int filterIndex,
    @Default(0) int pingInterval,
    @Default(false) bool autoReconnect,
    @Default(5) int reconnectInterval,
    @Default(5) int maxRetries,
  }) = _WebSocketRequestModel;

  factory WebSocketRequestModel.fromJson(Map<String, dynamic> json) =>
      _$WebSocketRequestModelFromJson(json);
}

const kWebSocketRequestEmptyModel = WebSocketRequestModel();
