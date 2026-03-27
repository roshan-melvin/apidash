import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import '../models/grpc_request_model.dart';
import 'grpc_reflection_service.dart';
import '../generated/google/protobuf/descriptor.pb.dart' as $descriptor;

enum GrpcEventType { connect, disconnect, send, receive, error }

class GrpcEvent {
  final DateTime timestamp;
  final GrpcEventType type;
  final String description;

  const GrpcEvent({
    required this.timestamp,
    required this.type,
    required this.description,
  });
}

class GrpcMessage {
  final String payload;
  final DateTime timestamp;
  final bool isIncoming;

  const GrpcMessage({
    required this.payload,
    required this.timestamp,
    this.isIncoming = false,
  });
}

class GrpcConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final String? connectedUrl;
  final List<GrpcMessage> messages;
  final List<GrpcEvent> eventLog;

  const GrpcConnectionState({
    this.isConnected = false,
    this.isConnecting = false,
    this.error,
    this.connectedUrl,
    this.messages = const [],
    this.eventLog = const [],
  });

  GrpcConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? error,
    bool clearError = false,
    String? connectedUrl,
    bool clearUrl = false,
    List<GrpcMessage>? messages,
    List<GrpcEvent>? eventLog,
  }) {
    return GrpcConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      error: clearError ? null : (error ?? this.error),
      connectedUrl: clearUrl ? null : (connectedUrl ?? this.connectedUrl),
      messages: messages ?? this.messages,
      eventLog: eventLog ?? this.eventLog,
    );
  }
}

class GrpcService {
  GrpcConnectionState _currentState = const GrpcConnectionState();
  final _stateController = StreamController<GrpcConnectionState>.broadcast();

  ClientChannel? _channel;
  final _reflectionService = GrpcReflectionService();
  Map<String, $descriptor.FileDescriptorProto>? _descriptors;
  GrpcMethodSignature? _methodSignature;
  GrpcRequestModel? _currentRequestModel;

  Stream<GrpcConnectionState> get stateStream => _stateController.stream;
  GrpcConnectionState get currentState => _currentState;

  Future<void> connect(GrpcRequestModel requestModel) async {
    await disconnect(); // Always close any lingering channel/state
    _currentRequestModel = requestModel;

    _updateState((state) => state.copyWith(
      isConnecting: true,
      clearError: true,
      clearUrl: true,
      messages: [],
      eventLog: [
        GrpcEvent(
          timestamp: DateTime.now(),
          type: GrpcEventType.connect,
          description: 'Connecting to ${requestModel.url}...',
        )
      ],
    ));

    try {
      final uriStr = !requestModel.url.startsWith('http') ? 'http://${requestModel.url}' : requestModel.url;
      final uri = Uri.parse(uriStr);
      final host = uri.host;
      final port = uri.hasPort ? uri.port : 80;

      _channel = ClientChannel(
        host,
        port: port,
        options: ChannelOptions(credentials: requestModel.useTls ? const ChannelCredentials.secure() : const ChannelCredentials.insecure()),
      );

      await _channel!.getConnection();
      
      _updateState((state) => state.copyWith(
        eventLog: [
          ...state.eventLog,
          GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.connect, description: 'Connected successfully to $host:$port. Loading reflection...')
        ]
      ));

      _descriptors = await _reflectionService.loadDescriptorsViaReflection(
        channel: _channel!,
        host: host,
        targetSymbol: requestModel.serviceName.isNotEmpty ? '${requestModel.serviceName}.${requestModel.methodName}' : null,
      );

      if (requestModel.serviceName.isNotEmpty && requestModel.methodName.isNotEmpty) {
        _methodSignature = _reflectionService.extractMethodSignature(
          serviceName: requestModel.serviceName,
          methodName: requestModel.methodName,
          descriptors: _descriptors!,
        );
      }

      _updateState((state) => state.copyWith(
        isConnecting: false,
        isConnected: true,
        connectedUrl: requestModel.url,
        eventLog: [
          ...state.eventLog,
          GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.connect, description: 'Reflection descriptors loaded successfully.')
        ]
      ));
    } catch (e) {
      debugPrint('gRPC Error: $e');
      if (_channel != null) {
        try {
          await _channel!.shutdown();
        } catch (_) {}
        _channel = null;
      }
      _updateState((state) => state.copyWith(
        isConnecting: false, error: e.toString(),
        eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.error, description: 'Failed: $e')]
      ));
    }
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      try {
        await _channel!.shutdown();
      } catch (e) {
        debugPrint("[gRPC] Error shutting down channel: $e");
      }
      _channel = null;
    }
    _descriptors = null;
    _methodSignature = null;
    _currentRequestModel = null;
    
    _updateState((state) => state.copyWith(
      isConnected: false, isConnecting: false,
      eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.disconnect, description: 'Disconnected')]
    ));
  }

  Future<void> send({required String message, GrpcRequestModel? requestModel}) async {
    if (requestModel != null) {
      _currentRequestModel = requestModel;
    }
    if (_channel == null || !_currentState.isConnected) {
      _updateState((state) => state.copyWith(error: 'Not connected.'));
      return;
    }
    
    // Attempt to re-extract method signature if not found (in case they typed it in after connecting)
    if (_descriptors != null && _currentRequestModel != null) {
      if (_currentRequestModel!.serviceName.isNotEmpty && _currentRequestModel!.methodName.isNotEmpty) {
        try {
          _methodSignature = _reflectionService.extractMethodSignature(
            serviceName: _currentRequestModel!.serviceName,
            methodName: _currentRequestModel!.methodName,
            descriptors: _descriptors!,
          );
        } catch (_) {}
      }
    }

    if (_descriptors == null || _methodSignature == null || _currentRequestModel == null) {
        _updateState((state) => state.copyWith(
            error: 'Not properly configured (missing descriptors or service/method).',
            eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.error, description: 'Service or Method missing/invalid.')]
        ));
        return;
    }

    _updateState((state) => state.copyWith(
      messages: [...state.messages, GrpcMessage(payload: message, timestamp: DateTime.now(), isIncoming: false)],
      eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.send, description: 'Message sent')]
    ));

    try {
      final inputTypeStr = _methodSignature!.requestFields.isNotEmpty ? _reflectionService.findMessageDescriptor(_reflectionService.extractMethodSignature(serviceName: _currentRequestModel!.serviceName, methodName: _currentRequestModel!.methodName, descriptors: _descriptors!).requestFields.first.messageType ?? "", _descriptors!)?.name : ""; 
      
      // We need to re-fetch the raw string names from method cache or similar?
      // Extract from method directly using descriptors
      var inputType = "";
      var outputType = "";
      
      $descriptor.ServiceDescriptorProto? serviceDesc;
      for (final fd in _descriptors!.values) {
        for (final svc in fd.service) {
          if (svc.name == _currentRequestModel!.serviceName || '${fd.package}.${svc.name}' == _currentRequestModel!.serviceName || svc.name == _currentRequestModel!.serviceName.split('.').last) {
            serviceDesc = svc;
            break;
          }
        }
        if (serviceDesc != null) break;
      }
      if (serviceDesc != null) {
        for (final m in serviceDesc.method) {
            if (m.name == _currentRequestModel!.methodName) {
                inputType = m.inputType;
                outputType = m.outputType;
            }
        }
      }

      final inputMessageDesc = _reflectionService.findMessageDescriptor(inputType, _descriptors!);
      final outputMessageDesc = _reflectionService.findMessageDescriptor(outputType, _descriptors!);

      if (inputMessageDesc == null || outputMessageDesc == null) {
        throw Exception('Descriptor for input/output not found');
      }

      final jsonPayload = message.trim().isEmpty ? <String, dynamic>{} : jsonDecode(message);
      
      final requestBytes = GrpcProtobufCodec.jsonToProtobuf(
        jsonPayload,
        inputMessageDesc,
        _descriptors!,
      );
      
      _updateState((state) => state.copyWith(
        eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.send, description: 'Serialized internal JSON into ${requestBytes.length} bytes')]
      ));

      final method = ClientMethod<List<int>, List<int>>(
        '/${_currentRequestModel!.serviceName}/${_currentRequestModel!.methodName}',
        (List<int> value) => value,
        (List<int> value) => value,
      );

      Map<String, String> metadata = {};
      for (int i=0; i<_currentRequestModel!.metadata.length; i++) {
        if (_currentRequestModel!.isMetadataEnabledList.length > i && _currentRequestModel!.isMetadataEnabledList[i]) {
            final m = _currentRequestModel!.metadata[i];
            if (m.name.isNotEmpty) {
                metadata[m.name] = m.value.toString();
            }
        }
      }
      
      if (metadata.isNotEmpty) {
        _updateState((state) => state.copyWith(
          eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.send, description: 'Sending Metadata: $metadata')]
        ));
      }
      
      final callOptions = CallOptions(timeout: const Duration(seconds: 30), metadata: metadata);

      if (_currentRequestModel!.callType == GrpcCallType.unary) {
        final call = _channel!.createCall(
            method,
            Stream.fromIterable([requestBytes]),
            callOptions
        );
        call.response.listen((data) {
             final respJson = GrpcProtobufCodec.protobufToJson(data, outputMessageDesc, _descriptors!);
             _updateState((state) => state.copyWith(
              eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.receive, description: 'Received ${data.length} bytes from unary stream.')],
          ));
             _updateState((state) => state.copyWith(
              messages: [...state.messages, GrpcMessage(payload: respJson, timestamp: DateTime.now(), isIncoming: true)],
              eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.receive, description: 'Unary response received')]
            ));
        }, onError: (e) {
            _updateState((state) => state.copyWith(
              error: e.toString(),
              eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.error, description: 'Unary error: $e')]
            ));
        });
      } else {
        // Stream
        final call = _channel!.createCall(
          method,
          Stream.fromIterable([requestBytes]), // Client streams not fully handled here yet, just sending one
          callOptions
        );

        call.response.listen((data) {
          final respJson = GrpcProtobufCodec.protobufToJson(data, outputMessageDesc, _descriptors!);
          _updateState((state) => state.copyWith(
            eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.receive, description: 'Received ${data.length} bytes from stream chunk.')],
          ));
          _updateState((state) => state.copyWith(
            messages: [...state.messages, GrpcMessage(payload: respJson, timestamp: DateTime.now(), isIncoming: true)],
            eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.receive, description: 'Received stream chunk')]
          ));
        }, onError: (e) {
          _updateState((state) => state.copyWith(
            error: e.toString(),
            eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.error, description: 'Stream error: $e')]
          ));
        });
      }
    } catch (e) {
      _updateState((state) => state.copyWith(
        error: e.toString(),
        eventLog: [...state.eventLog, GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.error, description: 'Invoke fail: $e')]
      ));
    }
  }

  void _updateState(GrpcConnectionState Function(GrpcConnectionState) updater) {
    _currentState = updater(_currentState);
    _stateController.add(_currentState);
  }

  void dispose() {
    _channel?.shutdown();
    _stateController.close();
  }
}
