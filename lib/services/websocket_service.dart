import 'dart:async';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/websocket_request_model.dart';
import 'get_channel.dart';
import 'get_channel.dart';

final _log = Logger();

enum WebSocketEventType {
  connect,
  disconnect,
  sendText,
  sendBinary,
  receiveText,
  receiveBinary,
  error,
}

class WebSocketEvent {
  final DateTime timestamp;
  final WebSocketEventType type;
  final String description;

  const WebSocketEvent({
    required this.timestamp,
    required this.type,
    required this.description,
  });
}

class WebSocketMessage {
  final dynamic payload;
  final bool isText;
  final DateTime timestamp;
  final bool isIncoming;

  const WebSocketMessage({
    required this.payload,
    required this.isText,
    required this.timestamp,
    required this.isIncoming,
  });
}

class WebSocketConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final List<WebSocketMessage> messages;
  final List<WebSocketEvent> eventLog;

  const WebSocketConnectionState({
    this.isConnected = false,
    this.isConnecting = false,
    this.error,
    this.messages = const [],
    this.eventLog = const [],
  });

  WebSocketConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? error,
    List<WebSocketMessage>? messages,
    List<WebSocketEvent>? eventLog,
  }) {
    return WebSocketConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      error: error ?? this.error,
      messages: messages ?? this.messages,
      eventLog: eventLog ?? this.eventLog,
    );
  }
}

class WebSocketService {
  WebSocketConnectionState _state = const WebSocketConnectionState();
  final _stateController = StreamController<WebSocketConnectionState>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;
  WebSocketConnectionState get currentState => _state;

  void _pushState(WebSocketConnectionState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  void _addEvent(WebSocketEvent event) {
    _pushState(_state.copyWith(eventLog: [..._state.eventLog, event]));
  }

  void _addMessage(WebSocketMessage message) {
    _pushState(_state.copyWith(messages: [..._state.messages, message]));
  }

  Future<void> connect(WebSocketRequestModel request) async {
    await disconnect();

    _pushState(_state.copyWith(
      isConnecting: true,
      isConnected: false,
      error: null,
      messages: [],
      eventLog: [],
    ));

    _addEvent(WebSocketEvent(
      timestamp: DateTime.now(),
      type: WebSocketEventType.connect,
      description: 'Connecting to ${request.url}...',
    ));

    try {
      final uri = Uri.parse(request.url);
      
      // Use factory to support headers on IO and gracefully degrade on Web
      _channel = getChannel(uri, request);

      // Successfully connected since connection is established synchronously or via Future depending on platform but stream opens connection automatically.
      // Wait for at least ready state or first event
      await _channel!.ready;
      
      _pushState(_state.copyWith(isConnected: true, isConnecting: false));
      _addEvent(WebSocketEvent(
        timestamp: DateTime.now(),
        type: WebSocketEventType.connect,
        description: 'Connected successfully to ${request.url}',
      ));

      _subscription = _channel!.stream.listen(
        (message) {
          final isText = message is String;
          _log.d("[WS] Received: $message");
          _addMessage(WebSocketMessage(
            payload: message,
            isText: isText,
            timestamp: DateTime.now(),
            isIncoming: true,
          ));
          _addEvent(WebSocketEvent(
            timestamp: DateTime.now(),
            type: isText ? WebSocketEventType.receiveText : WebSocketEventType.receiveBinary,
            description: 'Received ${isText ? "text" : "binary"} message',
          ));
        },
        onError: (error) {
          _log.e("[WS] Error: $error");
          _pushState(_state.copyWith(isConnected: false, isConnecting: false, error: 'Connection Error: $error'));
          _addEvent(WebSocketEvent(
            timestamp: DateTime.now(),
            type: WebSocketEventType.error,
            description: 'Error: $error',
          ));
        },
        onDone: () {
          _log.i("[WS] Connection closed");
          _pushState(_state.copyWith(isConnected: false, isConnecting: false, messages: [], eventLog: []));
          _addEvent(WebSocketEvent(
            timestamp: DateTime.now(),
            type: WebSocketEventType.disconnect,
            description: 'Connection closed by remote host. Code: ${_channel?.closeCode}, Reason: ${_channel?.closeReason}',
          ));
        },
      );

    } catch (e) {
      _log.e("[WS] Connection Failed: $e");
      _pushState(_state.copyWith(isConnected: false, isConnecting: false, error: e.toString()));
      _addEvent(WebSocketEvent(
        timestamp: DateTime.now(),
        type: WebSocketEventType.error,
        description: 'Failed to connect: $e',
      ));
    }
  }

  void sendMessage(dynamic payload, {bool isText = true}) {
    if (_channel != null && _state.isConnected) {
      _channel!.sink.add(payload);
      _addMessage(WebSocketMessage(
        payload: payload,
        isText: isText,
        timestamp: DateTime.now(),
        isIncoming: false,
      ));
      _addEvent(WebSocketEvent(
        timestamp: DateTime.now(),
        type: isText ? WebSocketEventType.sendText : WebSocketEventType.sendBinary,
        description: 'Sent ${isText ? "text" : "binary"} message',
      ));
    } else {
      _pushState(_state.copyWith(error: 'Cannot send message. Not connected to socket.'));
    }
  }

  Future<void> disconnect() async {
    if (_channel != null) {
      _addEvent(WebSocketEvent(
        timestamp: DateTime.now(),
        type: WebSocketEventType.disconnect,
        description: 'Disconnected by user.',
      ));
      await _channel!.sink.close(1000, 'Normal Closure');
      await _subscription?.cancel();
      _channel = null;
      _subscription = null;
      _pushState(_state.copyWith(isConnected: false, isConnecting: false, messages: [], eventLog: []));
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
  }
}
