import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:grpc/grpc.dart' as $grpc;
import '../generated/google/protobuf/descriptor.pb.dart' as $descriptor;
import '../generated/grpc/reflection/v1alpha/reflection.pb.dart' as $reflection;
import '../generated/grpc/reflection/v1alpha/reflection.pbgrpc.dart' as $reflection_grpc;

enum GrpcFieldKind {
  string, bytes, boolType, intType, doubleType, enumType, message, unknown,
}

class GrpcRequestFieldSchema {
  const GrpcRequestFieldSchema({
    required this.name,
    required this.jsonName,
    required this.kind,
    required this.isRepeated,
    this.enumValues = const [],
    this.messageType,
  });

  final String name;
  final String jsonName;
  final GrpcFieldKind kind;
  final bool isRepeated;
  final List<String> enumValues;
  final String? messageType;
}

class GrpcMethodSignature {
  const GrpcMethodSignature({
    required this.methodName,
    required this.requestFields,
    required this.responseFields,
    required this.responseTypeName,
  });

  final String methodName;
  final List<GrpcRequestFieldSchema> requestFields;
  final List<GrpcRequestFieldSchema> responseFields;
  final String responseTypeName;
}

class GrpcReflectionException implements Exception {
  const GrpcReflectionException(this.message);
  final String message;
  @override
  String toString() => 'GrpcReflectionException: {message}';
}

class GrpcReflectionService {
  final Map<String, Map<String, $descriptor.FileDescriptorProto>> _descriptorCache = {};
  final Map<String, (String, String)> _methodTypeCache = {};

  Future<Map<String, $descriptor.FileDescriptorProto>> loadDescriptorsViaReflection({
    required $grpc.ClientChannel channel,
    required String host,
    String? targetSymbol,
  }) async {
    final client = $reflection_grpc.ServerReflectionClient(channel);
    final descriptorMap = <String, $descriptor.FileDescriptorProto>{};

    if (targetSymbol == null || targetSymbol.isEmpty) {
      final services = await _listServices(client, host);
      for (final service in services) {
        await _fetchDescriptorsForSymbol(
          client: client,
          host: host,
          symbol: service,
          descriptorMap: descriptorMap,
        );
      }
    } else {
      await _fetchDescriptorsForSymbol(
        client: client,
        host: host,
        symbol: targetSymbol,
        descriptorMap: descriptorMap,
      );
    }
    return descriptorMap;
  }

  Future<List<String>> _listServices(
    $reflection_grpc.ServerReflectionClient client,
    String host,
  ) async {
    final req = $reflection.ServerReflectionRequest()
      ..host = host
      ..listServices = '*';
    final controller = StreamController<$reflection.ServerReflectionRequest>();
    controller.add(req);
    final responseStream = client.serverReflectionInfo(controller.stream);
    try {
      await for (final resp in responseStream.timeout(const Duration(seconds: 15), onTimeout: (sink) {
        sink.addError(GrpcReflectionException('Server Reflection timed out. Check TLS/SSL settings and port.'));
      })) {
        if (resp.hasListServicesResponse()) {
          return resp.listServicesResponse.service
              .map((s) => s.name)
              .where((s) => s.isNotEmpty)
              .toList(growable: false);
        }
        if (resp.hasErrorResponse()) {
          throw GrpcReflectionException('Reflection listServices failed: ${resp.errorResponse.errorMessage}');
        }
      }
    } finally {
      controller.close();
    }
    return const [];
  }

  Future<void> _fetchDescriptorsForSymbol({
    required $reflection_grpc.ServerReflectionClient client,
    required String host,
    required String symbol,
    required Map<String, $descriptor.FileDescriptorProto> descriptorMap,
  }) async {
    final req = $reflection.ServerReflectionRequest()
      ..host = host
      ..fileContainingSymbol = symbol;

    final controller = StreamController<$reflection.ServerReflectionRequest>();
    controller.add(req);
    final responseStream = client.serverReflectionInfo(controller.stream);
    
    try {
      await for (final resp in responseStream.timeout(const Duration(seconds: 15), onTimeout: (sink) {
        sink.addError(GrpcReflectionException('Server Reflection timed out. Check TLS/SSL settings and port.'));
      })) {
        if (resp.hasFileDescriptorResponse()) {
          for (final fdBytes in resp.fileDescriptorResponse.fileDescriptorProto) {
            final fd = $descriptor.FileDescriptorProto.fromBuffer(fdBytes);
            if (!descriptorMap.containsKey(fd.name)) {
              descriptorMap[fd.name] = fd;
            }
            for (final dep in fd.dependency) {
              if (!descriptorMap.containsKey(dep)) {
                await _resolveDescriptorsForFile(client, dep, descriptorMap, host);
              }
            }
          }
          break; // Stop after getting the response to prevent hanging
        } else if (resp.hasErrorResponse()) {
          throw GrpcReflectionException('Reflection symbol lookup failed: ${resp.errorResponse.errorMessage}');
        }
      }
    } finally {
      controller.close();
    }
  }

  Future<void> _resolveDescriptorsForFile(
    $reflection_grpc.ServerReflectionClient client,
    String filename,
    Map<String, $descriptor.FileDescriptorProto> descriptorMap,
    String host,
  ) async {
    if (descriptorMap.containsKey(filename)) return;

    final req = $reflection.ServerReflectionRequest()
      ..host = host
      ..fileByFilename = filename;

    final controller = StreamController<$reflection.ServerReflectionRequest>();
    controller.add(req);
    final responseStream = client.serverReflectionInfo(controller.stream);

    try {
      await for (final resp in responseStream.timeout(const Duration(seconds: 15), onTimeout: (sink) {
        sink.addError(GrpcReflectionException('Server Reflection timed out. Check TLS/SSL settings and port.'));
      })) {
        if (resp.hasFileDescriptorResponse()) {
          for (final fdBytes in resp.fileDescriptorResponse.fileDescriptorProto) {
            final fd = $descriptor.FileDescriptorProto.fromBuffer(fdBytes);
            descriptorMap[fd.name] = fd;
          }
          break;
        }
      }
    } finally {
      controller.close();
    }
  }

  GrpcMethodSignature extractMethodSignature({
    required String serviceName,
    required String methodName,
    required Map<String, $descriptor.FileDescriptorProto> descriptors,
  }) {
    final cacheKey = '${serviceName}/${methodName}';
    String inputType = '';
    String outputType = '';
    if (_methodTypeCache.containsKey(cacheKey)) {
      final cached = _methodTypeCache[cacheKey]!;
      inputType = cached.$1;
      outputType = cached.$2;
    } else {
      $descriptor.ServiceDescriptorProto? serviceDesc;
      String? servicePackage;
      for (final fd in descriptors.values) {
        for (final svc in fd.service) {
          if (svc.name == serviceName || '${fd.package}.${svc.name}' == serviceName || svc.name == serviceName.split('.').last) {
            serviceDesc = svc;
            servicePackage = fd.package;
            break;
          }
        }
        if (serviceDesc != null) break;
      }

      if (serviceDesc == null) throw GrpcReflectionException('Service not found: $serviceName');

      $descriptor.MethodDescriptorProto? methodDesc;
      for (final method in serviceDesc.method) {
        if (method.name == methodName) {
          methodDesc = method;
          break;
        }
      }

      if (methodDesc == null) throw GrpcReflectionException('Method ${methodName} not found in ${serviceName}');

      inputType = methodDesc.inputType;
      outputType = methodDesc.outputType;

      if (!inputType.startsWith('.')) {
        inputType = servicePackage != null && servicePackage.isNotEmpty ? '.${servicePackage}.${inputType}' : '.${inputType}';
      }
      if (!outputType.startsWith('.')) {
        outputType = servicePackage != null && servicePackage.isNotEmpty ? '.${servicePackage}.${outputType}' : '.${outputType}';
      }
      _methodTypeCache[cacheKey] = (inputType, outputType);
    }

    final inputMessageDesc = findMessageDescriptor(inputType, descriptors);
    if (inputMessageDesc == null) throw GrpcReflectionException('Input message type not found: $inputType');

    final requestFields = inputMessageDesc.field.map((field) {
      final kind = _kindForField(field);
      return GrpcRequestFieldSchema(
        name: field.name,
        jsonName: field.jsonName.isEmpty ? field.name : field.jsonName,
        kind: kind,
        isRepeated: field.label.value == 3,
        enumValues: kind == GrpcFieldKind.enumType ? _resolveEnumValues(field.typeName, descriptors) : const [],
        messageType: kind == GrpcFieldKind.message ? field.typeName : null,
      );
    }).toList(growable: false);

    final outputMessageDesc = findMessageDescriptor(outputType, descriptors);
    if (outputMessageDesc == null) throw GrpcReflectionException('Output message type not found: $outputType');

    final responseFields = outputMessageDesc.field.map((field) {
      final kind = _kindForField(field);
      return GrpcRequestFieldSchema(
        name: field.name,
        jsonName: field.jsonName.isEmpty ? field.name : field.jsonName,
        kind: kind,
        isRepeated: field.label.value == 3,
        enumValues: kind == GrpcFieldKind.enumType ? _resolveEnumValues(field.typeName, descriptors) : const [],
        messageType: kind == GrpcFieldKind.message ? field.typeName : null,
      );
    }).toList(growable: false);

    return GrpcMethodSignature(
      methodName: methodName,
      requestFields: requestFields,
      responseFields: responseFields,
      responseTypeName: outputType,
    );
  }

  $descriptor.DescriptorProto? findMessageDescriptor(String typeName, Map<String, $descriptor.FileDescriptorProto> descriptors) {
    var name = typeName;
    if (name.startsWith('.')) name = name.substring(1);

    for (final fd in descriptors.values) {
      for (final msg in fd.messageType) {
        final fullName = fd.package.isEmpty ? msg.name : '${fd.package}.${msg.name}';
        if (fullName == name || msg.name == name) return msg;
      }
    }
    return null;
  }

  GrpcFieldKind _kindForField($descriptor.FieldDescriptorProto field) {
    switch (field.type.value) {
      case 1: case 2: return GrpcFieldKind.doubleType;
      case 3: case 4: case 5: case 6: case 7: case 13: case 15: case 16: case 17: case 18: return GrpcFieldKind.intType;
      case 8: return GrpcFieldKind.boolType;
      case 9: return GrpcFieldKind.string;
      case 12: return GrpcFieldKind.bytes;
      case 11: return GrpcFieldKind.message;
      case 14: return GrpcFieldKind.enumType;
      default: return GrpcFieldKind.unknown;
    }
  }

  List<String> _resolveEnumValues(String typeName, Map<String, $descriptor.FileDescriptorProto> descriptors) {
    var normalized = typeName;
    if (normalized.startsWith('.')) normalized = normalized.substring(1);
    for (final fd in descriptors.values) {
      for (final enumDesc in fd.enumType) {
        final fullName = fd.package.isEmpty ? enumDesc.name : '${fd.package}.${enumDesc.name}';
        if (fullName == normalized || enumDesc.name == normalized) {
          return enumDesc.value.map((v) => v.name).toList(growable: false);
        }
      }
    }
    return const [];
  }
}

class GrpcProtobufCodec {
  static List<int> jsonToProtobuf(
    Map<String, dynamic> jsonPayload,
    $descriptor.DescriptorProto messageDesc,
    Map<String, $descriptor.FileDescriptorProto> descriptors,
  ) {
    final msg = _DynamicMessage(messageDesc);
    msg.mergeFromJson(jsonPayload, descriptors);
    return msg.toBuffer();
  }

  static String protobufToJson(
    List<int> bytes,
    $descriptor.DescriptorProto messageDesc,
    Map<String, $descriptor.FileDescriptorProto> descriptors,
  ) {
    final msg = _DynamicMessage(messageDesc);
    msg.mergeFromBuffer(bytes, descriptors);
    final jsonMap = msg.toJson(descriptors);
    return const JsonEncoder.withIndent('  ').convert(jsonMap);
  }
}

class _DynamicMessage {
  final $descriptor.DescriptorProto descriptor;
  final Map<int, dynamic> fields = {};

  _DynamicMessage(this.descriptor);

  void mergeFromJson(Map<String, dynamic> json, Map<String, $descriptor.FileDescriptorProto> descriptors) {
    for (final field in descriptor.field) {
      final jsonKey = field.jsonName.isEmpty ? field.name : field.jsonName;
      if (!json.containsKey(jsonKey)) continue;
      fields[field.number] = _coerceJsonValue(json[jsonKey], field, descriptors);
    }
  }

  void mergeFromBuffer(List<int> buffer, Map<String, $descriptor.FileDescriptorProto> descriptors) {
    var offset = 0;
    final bufferView = Uint8List.fromList(buffer);
    while (offset < buffer.length) {
      final (tag, wireType, newOffset) = _readFieldTag(bufferView, offset);
      offset = newOffset;
      final fieldNum = tag >> 3;
      final field = descriptor.field.firstWhere((f) => f.number == fieldNum, orElse: () => $descriptor.FieldDescriptorProto()..number = -1);
      if (field.number == -1) {
        (_, offset) = _skipField(bufferView, offset, wireType);
        continue;
      }
      final (value, newOff) = _readFieldValue(bufferView, offset, wireType, field, descriptors);
      fields[fieldNum] = value;
      offset = newOff;
    }
  }

  List<int> toBuffer() {
    final result = <int>[];
    for (final entry in fields.entries) {
      final field = descriptor.field.firstWhere((f) => f.number == entry.key, orElse: () => $descriptor.FieldDescriptorProto()..number = -1);
      if (field.number == -1) continue;
      final fieldTag = (entry.key << 3) | _wireTypeForField(field);
      _appendVarint(result, fieldTag);
      final value = entry.value;
      if (value == null) continue;
      if (field.label.value == 3) {
        for (final item in (value as List)) _appendFieldValue(result, item, field);
      } else {
        _appendFieldValue(result, value, field);
      }
    }
    return result;
  }

  Map<String, dynamic> toJson(Map<String, $descriptor.FileDescriptorProto> descriptors) {
    final result = <String, dynamic>{};
    for (final entry in fields.entries) {
      final field = descriptor.field.firstWhere((f) => f.number == entry.key, orElse: () => $descriptor.FieldDescriptorProto()..number = -1);
      if (field.number == -1) continue;
      final jsonKey = field.jsonName.isEmpty ? field.name : field.jsonName;
      result[jsonKey] = _valueToJson(entry.value, field, descriptors);
    }
    return result;
  }

  dynamic _coerceJsonValue(dynamic jsonValue, $descriptor.FieldDescriptorProto field, Map<String, $descriptor.FileDescriptorProto> descriptors) {
    if (jsonValue == null) return null;
    switch (field.type.value) {
      case 1: case 2: return (jsonValue as num).toDouble();
      case 3: case 4: case 5: case 6: case 7: case 13: case 15: case 16: case 17: case 18: return (jsonValue as num).toInt();
      case 8: return jsonValue as bool;
      case 9: return jsonValue as String;
      case 12: return jsonValue is List ? Uint8List.fromList(jsonValue.whereType<num>().map((e) => e.toInt()).toList()) : utf8.encode(jsonValue.toString());
      default: return jsonValue;
    }
  }

  dynamic _valueToJson(dynamic value, $descriptor.FieldDescriptorProto field, Map<String, $descriptor.FileDescriptorProto> descriptors) {
    if (value == null) return null;
    if (field.label.value == 3 && value is List) return value.map((v) => _valueToJson(v, field, descriptors)).toList();
    if (field.type.value == 12) {
      final bytes = value is Uint8List ? value : (value is List<int> ? Uint8List.fromList(value) : Uint8List.fromList(utf8.encode(value.toString())));
      return {'__apidashBytes': true, 'base64': base64Encode(bytes)};
    }
    return value;
  }

  static (int, int, int) _readFieldTag(Uint8List buffer, int offset) {
    final (tag, newOff) = _readVarint(buffer, offset);
    return (tag, tag & 0x07, newOff);
  }

  static (int, int) _readVarint(Uint8List buffer, int offset) {
    int value = 0, shift = 0, i = offset;
    while (i < buffer.length) {
      final byte = buffer[i++];
      value |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return (value, i);
  }

  static void _appendVarint(List<int> buffer, int value) {
    while ((value & 0xffffff80) != 0) {
      buffer.add((value & 0x7f) | 0x80);
      value >>= 7;
    }
    buffer.add(value & 0x7f);
  }

  static (dynamic, int) _readFieldValue(Uint8List buffer, int offset, int wireType, $descriptor.FieldDescriptorProto field, Map<String, $descriptor.FileDescriptorProto> descriptors) {
    if (wireType == 0) return _readVarint(buffer, offset);
    if (wireType == 1) return (Uint8List.sublistView(buffer, offset, offset + 8), offset + 8);
    if (wireType == 5) return (Uint8List.sublistView(buffer, offset, offset + 4), offset + 4);
    if (wireType == 2) {
      final (len, newOff) = _readVarint(buffer, offset);
      final bytes = Uint8List.sublistView(buffer, newOff, newOff + len);
      if (field.type.value == 9) {
        try { return (utf8.decode(bytes), newOff + len); } catch (_) {}
      }
      return (bytes, newOff + len);
    }
    throw GrpcReflectionException('Unsupported wire type: ${wireType}');
  }

  static (dynamic, int) _skipField(Uint8List buffer, int offset, int wireType) {
    if (wireType == 0) return _readVarint(buffer, offset);
    if (wireType == 1) return (null, offset + 8);
    if (wireType == 5) return (null, offset + 4);
    if (wireType == 2) {
      final (len, newOff) = _readVarint(buffer, offset);
      return (null, newOff + len);
    }
    throw GrpcReflectionException('Unsupported wire type: ${wireType}');
  }

  static void _appendFieldValue(List<int> buffer, dynamic value, $descriptor.FieldDescriptorProto field) {
    if (value is int) _appendVarint(buffer, value);
    else if (value is double) {
      final data = ByteData(8)..setFloat64(0, value, Endian.little);
      buffer.addAll(data.buffer.asUint8List(0, 8));
    }
    else if (value is bool) _appendVarint(buffer, value ? 1 : 0);
    else if (value is String) {
      final bytes = utf8.encode(value);
      _appendVarint(buffer, bytes.length);
      buffer.addAll(bytes);
    }
    else if (value is List<int>) {
      _appendVarint(buffer, value.length);
      buffer.addAll(value);
    }
    else if (value is Uint8List) {
      _appendVarint(buffer, value.length);
      buffer.addAll(value);
    }
  }

  static int _wireTypeForField($descriptor.FieldDescriptorProto field) {
    switch (field.type.value) {
      case 1: case 2: return 5;
      case 3: case 4: case 5: case 6: case 7: case 13: case 15: case 16: case 17: case 18: return 0;
      case 8: case 9: case 12: case 11: case 14: return 2;
      default: return 0;
    }
  }
}
