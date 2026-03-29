import 'package:apidash_core/apidash_core.dart';
import 'models.dart';
import 'mqtt_request_model.dart';
import 'websocket_request_model.dart';
import 'grpc_request_model.dart';

part 'history_request_model.freezed.dart';

part 'history_request_model.g.dart';

@freezed
abstract class HistoryRequestModel with _$HistoryRequestModel {
  @JsonSerializable(explicitToJson: true, anyMap: true)
  const factory HistoryRequestModel({
    required String historyId,
    required HistoryMetaModel metaData,
    HttpRequestModel? httpRequestModel,
    AIRequestModel? aiRequestModel,
    MQTTRequestModel? mqttRequestModel,
    WebSocketRequestModel? websocketRequestModel,
    GrpcRequestModel? grpcRequestModel,
    required HttpResponseModel httpResponseModel,
    String? preRequestScript,
    String? postRequestScript,
    AuthModel? authModel,
  }) = _HistoryRequestModel;

  factory HistoryRequestModel.fromJson(Map<String, Object?> json) =>
      _$HistoryRequestModelFromJson(json);
}
