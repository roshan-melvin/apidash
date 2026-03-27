// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grpc_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GrpcRequestModel _$GrpcRequestModelFromJson(Map<String, dynamic> json) =>
    _GrpcRequestModel(
      url: json['url'] as String? ?? '',
      useTls: json['useTls'] as bool? ?? false,
      serviceName: json['serviceName'] as String? ?? '',
      methodName: json['methodName'] as String? ?? '',
      callType:
          $enumDecodeNullable(_$GrpcCallTypeEnumMap, json['callType']) ??
          GrpcCallType.unary,
      descriptorSource:
          $enumDecodeNullable(
            _$GrpcDescriptorSourceEnumMap,
            json['descriptorSource'],
          ) ??
          GrpcDescriptorSource.reflection,
      metadata:
          (json['metadata'] as List<dynamic>?)
              ?.map((e) => NameValueModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isMetadataEnabledList:
          (json['isMetadataEnabledList'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const [],
      requestJson: json['requestJson'] as String? ?? '',
      requestTabIndex: (json['requestTabIndex'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$GrpcRequestModelToJson(
  _GrpcRequestModel instance,
) => <String, dynamic>{
  'url': instance.url,
  'useTls': instance.useTls,
  'serviceName': instance.serviceName,
  'methodName': instance.methodName,
  'callType': _$GrpcCallTypeEnumMap[instance.callType]!,
  'descriptorSource': _$GrpcDescriptorSourceEnumMap[instance.descriptorSource]!,
  'metadata': instance.metadata,
  'isMetadataEnabledList': instance.isMetadataEnabledList,
  'requestJson': instance.requestJson,
  'requestTabIndex': instance.requestTabIndex,
};

const _$GrpcCallTypeEnumMap = {
  GrpcCallType.unary: 'unary',
  GrpcCallType.serverStreaming: 'serverStreaming',
  GrpcCallType.clientStreaming: 'clientStreaming',
  GrpcCallType.bidirectionalStreaming: 'bidirectionalStreaming',
};

const _$GrpcDescriptorSourceEnumMap = {
  GrpcDescriptorSource.reflection: 'reflection',
  GrpcDescriptorSource.protoUpload: 'protoUpload',
};
