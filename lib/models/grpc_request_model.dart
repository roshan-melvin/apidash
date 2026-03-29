import 'package:apidash_core/apidash_core.dart'; // For NameValueModel

part 'grpc_request_model.freezed.dart';
part 'grpc_request_model.g.dart';

enum GrpcCallType {
  unary('Unary'),
  serverStreaming('Server Streaming'),
  clientStreaming('Client Streaming'),
  bidirectionalStreaming('Bidirectional Streaming');

  const GrpcCallType(this.label);
  final String label;
}

enum GrpcDescriptorSource { reflection, protoUpload }

@freezed
abstract class GrpcRequestModel with _$GrpcRequestModel {
  const factory GrpcRequestModel({
    @Default('') String url,

    @Default(false) bool useTls,
    @Default('') String serviceName,
    @Default('') String methodName,
    @Default(GrpcCallType.unary) GrpcCallType callType,
    @Default(GrpcDescriptorSource.reflection)
    GrpcDescriptorSource descriptorSource,
    @Default([]) List<NameValueModel> metadata,
    @Default([]) List<bool> isMetadataEnabledList,
    @Default('') String requestJson,
    @Default(0) int requestTabIndex,
  }) = _GrpcRequestModel;

  factory GrpcRequestModel.fromJson(Map<String, dynamic> json) =>
      _$GrpcRequestModelFromJson(json);
}
