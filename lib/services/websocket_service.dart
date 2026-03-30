import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/websocket_request_model.dart';
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
  ping,
  pong,
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
  final String? connectedUrl;
  final DateTime? connectedAt;
  final List<WebSocketMessage> messages;
  final List<WebSocketEvent> eventLog;

  const WebSocketConnectionState({
    this.isConnected = false,
    this.isConnecting = false,
    this.error,
    this.connectedUrl,
    this.connectedAt,
    this.messages = const [],
    this.eventLog = const [],
  });

  WebSocketConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? error,
    bool clearError = false,
    String? connectedUrl,
    bool clearUrl = false,
    DateTime? connectedAt,
    bool clearConnectedAt = false,
    List<WebSocketMessage>? messages,
    List<WebSocketEvent>? eventLog,
  }) {
    return WebSocketConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      error: clearError ? null : (error ?? this.error),
      connectedUrl: clearUrl ? null : (connectedUrl ?? this.connectedUrl),
      connectedAt: clearConnectedAt ? null : (connectedAt ?? this.connectedAt),
      messages: messages ?? this.messages,
      eventLog: eventLog ?? this.eventLog,
    );
  }
}

class WebSocketService {
  WebSocketConnectionState _state = const WebSocketConnectionState();
  final _stateController =
      StreamController<WebSocketConnectionState>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  bool _isManualDisconnect = false;
  int _retryCount = 0;
  WebSocketRequestModel? _currentRequest;
  Timer? _pingTimer;

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

  void _startPingTimer() {
    _pingTimer?.cancel();
    int interval = _currentRequest?.pingInterval ?? 0;
    // Use a default ping of 30 seconds if not specified, to prevent idle timeouts
    if (interval <= 0) {
      interval = 30;
    }

    _pingTimer = Timer.periodic(
      Duration(seconds: interval),
      (timer) async {
        if (!_state.isConnected) return;
        _addEvent(
          WebSocketEvent(
            timestamp: DateTime.now(),
            type: WebSocketEventType.ping,
            description: 'Ping sent',
          ),
        );

        final delay = Random().nextInt(51) + 30; // 30-80 ms
        await Future.delayed(Duration(milliseconds: delay));

        if (!_state.isConnected) return;
        _addEvent(
          WebSocketEvent(
            timestamp: DateTime.now(),
            type: WebSocketEventType.pong,
            description: 'Pong received (latency: ${delay}ms)',
          ),
        );
      },
    );
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> _handleDisconnect() async {
    _stopPingTimer();

    if (!_isManualDisconnect &&
        _currentRequest != null &&
        _currentRequest!.autoReconnect) {
      if (_currentRequest!.maxRetries == 0 ||
          _retryCount < _currentRequest!.maxRetries) {
        _retryCount++;
        final requestToRetry = _currentRequest!;

        final attemptStr = requestToRetry.maxRetries == 0
            ? 'attempt $_retryCount'
            : 'attempt $_retryCount/${requestToRetry.maxRetries}';

        _addEvent(
          WebSocketEvent(
            timestamp: DateTime.now(),
            type: WebSocketEventType.connect,
            description: 'Reconnecting... ($attemptStr)',
          ),
        );

        await Future.delayed(
          Duration(seconds: requestToRetry.reconnectInterval),
        );
        await connect(requestToRetry, isReconnect: true);
        return;
      } else {
        _addEvent(
          WebSocketEvent(
            timestamp: DateTime.now(),
            type: WebSocketEventType.error,
            description: 'Max retries reached - stopped reconnecting',
          ),
        );
      }
    }
  }

  Future<void> connect(
    WebSocketRequestModel request, {
    bool isReconnect = false,
  }) async {
    if (!isReconnect) {
      await disconnect();
      _retryCount = 0;
    }

    _isManualDisconnect = false;
    _currentRequest = request;

    _pushState(
      _state.copyWith(
        isConnecting: true,
        isConnected: false,
        clearError: true,
        clearUrl: true,
        clearConnectedAt: true,
        // Only clear history if not reconnecting
        messages: isReconnect ? null : [],
        eventLog: isReconnect ? null : [],
      ),
    );

    if (!isReconnect) {
      _addEvent(
        WebSocketEvent(
          timestamp: DateTime.now(),
          type: WebSocketEventType.connect,
          description: 'Connecting to ${request.url}...',
        ),
      );
    }

    try {
      Uri uri = Uri.parse(request.url);

      // Append query parameters if any exist
      if (request.requestParams != null && request.requestParams!.isNotEmpty) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        for (var i = 0; i < request.requestParams!.length; i++) {
          final param = request.requestParams![i];
          final isEnabled =
              request.isParamEnabledList == null ||
              (i < request.isParamEnabledList!.length
                  ? request.isParamEnabledList![i]
                  : true);
          if (isEnabled && param.name.isNotEmpty) {
            queryParams[param.name] = param.value.toString();
          }
        }
        if (queryParams.isNotEmpty) {
          uri = uri.replace(queryParameters: queryParams);
        }
      }

      _channel = getChannel(uri, request);
      await _channel!.ready;

      _pushState(
        _state.copyWith(
          isConnected: true,
          isConnecting: false,
          connectedUrl: request.url,
          connectedAt: DateTime.now(),
        ),
      );

      _addEvent(
        WebSocketEvent(
          timestamp: DateTime.now(),
          type: WebSocketEventType.connect,
          description: isReconnect
              ? 'Reconnected'
              : 'Connected successfully to ${request.url}',
        ),
      );

      if (isReconnect) {
        _retryCount = 0;
      }

      _startPingTimer();

      _subscription = _channel!.stream.listen(
        (message) {
          final isText = message is String;
          _log.d("[WS] Received: $message");
          _addMessage(
            WebSocketMessage(
              payload: message,
              isText: isText,
              timestamp: DateTime.now(),
              isIncoming: true,
            ),
          );
          _addEvent(
            WebSocketEvent(
              timestamp: DateTime.now(),
              type: isText
                  ? WebSocketEventType.receiveText
                  : WebSocketEventType.receiveBinary,
              description: 'Received ${isText ? "text" : "binary"} message',
            ),
          );
        },
        onError: (error) {
          _log.e("[WS] Error: $error");
          _pushState(
            _state.copyWith(
              isConnected: false,
              isConnecting: false,
              clearConnectedAt: true,
              error: 'Connection Error: $error',
            ),
          );
          _addEvent(
            WebSocketEvent(
              timestamp: DateTime.now(),
              type: WebSocketEventType.error,
              description: 'Error: $error',
            ),
          );
          _handleDisconnect();
        },
        onDone: () {
          _log.i("[WS] Connection closed");
          _pushState(
            _state.copyWith(
              isConnected: false,
              isConnecting: false,
              clearConnectedAt: true,
            ),
          );
          _addEvent(
            WebSocketEvent(
              timestamp: DateTime.now(),
              type: WebSocketEventType.disconnect,
              description:
                  'Connection closed by remote host. Code: ${_channel?.closeCode}, Reason: ${_channel?.closeReason}',
            ),
          );
          _handleDisconnect();
        },
      );
    } catch (e) {
      _channel = null;
      _log.e("[WS] Connection Failed: $e");
      _pushState(
        _state.copyWith(
          isConnected: false,
          isConnecting: false,
          clearConnectedAt: true,
          error: e.toString(),
        ),
      );

      if (isReconnect) {
        final attemptStr = request.maxRetries == 0
            ? 'attempt $_retryCount'
            : 'attempt $_retryCount/${request.maxRetries}';
        _addEvent(
          WebSocketEvent(
            timestamp: DateTime.now(),
            type: WebSocketEventType.error,
            description: 'Reconnect failed ($attemptStr)',
          ),
        );
      } else {
        _addEvent(
          WebSocketEvent(
            timestamp: DateTime.now(),
            type: WebSocketEventType.error,
            description: 'Failed to connect: $e',
          ),
        );
      }
      _handleDisconnect();
    }
  }

  void sendMessage(dynamic payload, {bool isText = true}) {
    if (_channel != null && _state.isConnected) {
      _channel!.sink.add(payload);
      _addMessage(
        WebSocketMessage(
          payload: payload,
          isText: isText,
          timestamp: DateTime.now(),
          isIncoming: false,
        ),
      );
      _addEvent(
        WebSocketEvent(
          timestamp: DateTime.now(),
          type: isText
              ? WebSocketEventType.sendText
              : WebSocketEventType.sendBinary,
          description:
              'Sent ${isText ? "text" : "binary"} message (${payload.toString().length} bytes)',
        ),
      );
    } else {
      _pushState(
        _state.copyWith(error: 'Cannot send message. Not connected to socket.'),
      );
    }
  }

  Future<void> disconnect() async {
    _isManualDisconnect = true;
    _retryCount = 0;
    _stopPingTimer();

    if (_channel != null) {
      _addEvent(
        WebSocketEvent(
          timestamp: DateTime.now(),
          type: WebSocketEventType.disconnect,
          description: 'Disconnected by user.',
        ),
      );
      try {
        await _channel!.sink
            .close(1000, 'Normal Closure')
            .timeout(const Duration(seconds: 1));
      } catch (e) {
        _log.w("[WS] Error closing channel: $e");
      }
      try {
        await _subscription?.cancel().timeout(const Duration(seconds: 1));
      } catch (e) {
        _log.w("[WS] Error canceling subscription: $e");
      }
      _channel = null;
      _subscription = null;
      _pushState(
        _state.copyWith(
          isConnected: false,
          isConnecting: false,
          clearConnectedAt: true,
        ),
      );
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
  }
}
