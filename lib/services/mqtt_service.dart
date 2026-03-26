import 'dart:async';
import 'package:logger/logger.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/mqtt_request_model.dart';

final _log = Logger();

// ─── Enums ────────────────────────────────────────────────────────────────────

enum MQTTEventType {
  connect,
  disconnect,
  subscribe,
  unsubscribe,
  send,
  receive,
  error,
}

// ─── Value Types (plain Dart, not freezed — no JSON persistence needed) ───────

class MQTTEvent {
  final DateTime timestamp;
  final MQTTEventType type;
  final String? topic;
  final String? payload;
  final String description;

  const MQTTEvent({
    required this.timestamp,
    required this.type,
    this.topic,
    this.payload,
    required this.description,
  });
}

class MQTTMessage {
  final String topic;
  final String payload;
  final DateTime timestamp;
  final bool isIncoming;

  const MQTTMessage({
    required this.topic,
    required this.payload,
    required this.timestamp,
    required this.isIncoming,
  });
}

class MQTTConnectionState {
  final bool isConnected;
  final String? error;
  final List<MQTTMessage> messages;
  final List<MQTTEvent> eventLog;

  const MQTTConnectionState({
    this.isConnected = false,
    this.error,
    this.messages = const [],
    this.eventLog = const [],
  });

  MQTTConnectionState copyWith({
    bool? isConnected,
    String? error,
    List<MQTTMessage>? messages,
    List<MQTTEvent>? eventLog,
  }) {
    return MQTTConnectionState(
      isConnected: isConnected ?? this.isConnected,
      error: error ?? this.error,
      messages: messages ?? this.messages,
      eventLog: eventLog ?? this.eventLog,
    );
  }
}

// ─── MQTT Service ─────────────────────────────────────────────────────────────

class MQTTService {
  MqttClient? _client;
  MQTTConnectionState _state = const MQTTConnectionState();
  final _stateController =
      StreamController<MQTTConnectionState>.broadcast();
  final _messages = <MQTTMessage>[];
  final _eventLog = <MQTTEvent>[];

  Stream<MQTTConnectionState> get stateStream => _stateController.stream;
  MQTTConnectionState get currentState => _state;

  bool get isConnected =>
      _client != null &&
      _client!.connectionStatus?.state == MqttConnectionState.connected;

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _addEvent(MQTTEvent event) {
    _eventLog.add(event);
    if (_eventLog.length > 200) _eventLog.removeAt(0);
    _pushState(_state.copyWith(eventLog: List.from(_eventLog)));
  }

  void _addMessage(MQTTMessage message) {
    _messages.add(message);
    _pushState(_state.copyWith(messages: List.from(_messages)));
  }

  void _pushState(MQTTConnectionState newState) {
    _state = newState.copyWith(eventLog: List.from(_eventLog));
    _stateController.add(_state);
  }

  // ── Callbacks from mqtt_client ───────────────────────────────────────────────

  void _onConnected() {
    _log.i('[MQTT] Connected to broker');
    _addEvent(MQTTEvent(
      timestamp: DateTime.now(),
      type: MQTTEventType.connect,
      description: 'Connected to broker',
    ));
    _pushState(_state.copyWith(isConnected: true, error: null));
  }

  void _onDisconnected() {
    _log.i('[MQTT] Disconnected from broker');
    _addEvent(MQTTEvent(
      timestamp: DateTime.now(),
      type: MQTTEventType.disconnect,
      description: 'Disconnected from broker',
    ));
    _pushState(_state.copyWith(isConnected: false));
  }

  void _onSubscribed(String topic) {
    _log.i('[MQTT] Subscribed to $topic');
    _addEvent(MQTTEvent(
      timestamp: DateTime.now(),
      type: MQTTEventType.subscribe,
      topic: topic,
      description: 'Subscribed to topic $topic',
    ));
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      String payload = '';
      try {
        final pub = msg.payload as MqttPublishMessage;
        payload =
            MqttPublishPayload.bytesToStringAsString(pub.payload.message);
      } catch (e) {
        payload = msg.payload.toString();
      }
      _log.d('[MQTT] Received on ${msg.topic}: $payload');
      _addMessage(MQTTMessage(
        topic: msg.topic,
        payload: payload,
        timestamp: DateTime.now(),
        isIncoming: true,
      ));
      _addEvent(MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.receive,
        topic: msg.topic,
        payload: payload,
        description: 'Message received from ${msg.topic}',
      ));
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  Future<bool> connect(MQTTRequestModel request) async {
    _log.i('[MQTT] Connecting to ${request.brokerUrl}:${request.port}');
    _eventLog.clear();
    _messages.clear();

    try {
      String brokerUrl = request.brokerUrl.trim();
      if (!brokerUrl.contains('://')) {
        brokerUrl = 'mqtt://$brokerUrl';
      }
      final uri = Uri.parse(brokerUrl);
      final isWebSocket = uri.scheme == 'ws' || uri.scheme == 'wss';
      final uniqueId =
          'apidash_${DateTime.now().millisecondsSinceEpoch}';
      final clientId =
          request.clientId.isNotEmpty ? request.clientId : uniqueId;

      if (isWebSocket) {
        _client = MqttServerClient(uri.toString(), clientId)
          ..useWebSocket = true
          ..port = uri.hasPort ? uri.port : 9001;
      } else {
        _client = MqttServerClient(uri.host, clientId)
          ..port = request.port == 0 ? 1883 : request.port;
      }

      _client!
        ..keepAlivePeriod = request.keepAlive
        ..connectTimeoutPeriod = request.connectTimeout * 1000
        ..onDisconnected = _onDisconnected
        ..onConnected = _onConnected
        ..onSubscribed = _onSubscribed;

      final connMsg = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillTopic('apidash/disconnect')
          .withWillMessage('Client disconnected')
          .withWillQos(MqttQos.atLeastOnce);

      if (request.cleanSession) connMsg.startClean();
      if (request.username.isNotEmpty) {
        connMsg.authenticateAs(
          request.username,
          request.password.isEmpty ? null : request.password,
        );
      }
      _client!.connectionMessage = connMsg;

      await _client!.connect();

      if (_client!.connectionStatus!.state ==
          MqttConnectionState.connected) {
        for (final topic in request.topics.where((t) => t.subscribe)) {
          await subscribe(topic.topic, topic.qos);
        }
        _client!.updates!.listen(_onMessageReceived);
        return true;
      } else {
        final errMsg =
            'Failed to connect: ${_client!.connectionStatus}';
        _log.e('[MQTT] $errMsg');
        _addEvent(MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.error,
          description: errMsg,
        ));
        _pushState(_state.copyWith(isConnected: false, error: errMsg));
        return false;
      }
    } catch (e) {
      final errMsg = 'Connection error: $e';
      _log.e('[MQTT] $errMsg');
      _addEvent(MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.error,
        description: errMsg,
      ));
      _pushState(_state.copyWith(isConnected: false, error: errMsg));
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_client != null && isConnected) {
      _client!.disconnect();
    }
    _client = null;
    _pushState(const MQTTConnectionState());
  }

  Future<bool> subscribe(String topic, int qos) async {
    if (!isConnected) return false;
    try {
      _client!.subscribe(topic, MqttQos.values[qos.clamp(0, 2)]);
      return true;
    } catch (e) {
      final errMsg = 'Subscribe error: $e';
      _log.e('[MQTT] $errMsg');
      _addEvent(MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.error,
        topic: topic,
        description: errMsg,
      ));
      _pushState(_state.copyWith(error: errMsg));
      return false;
    }
  }

  Future<bool> unsubscribe(String topic) async {
    if (!isConnected) return false;
    try {
      _client!.unsubscribe(topic);
      _addEvent(MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.unsubscribe,
        topic: topic,
        description: 'Unsubscribed from $topic',
      ));
      return true;
    } catch (e) {
      final errMsg = 'Unsubscribe error: $e';
      _log.e('[MQTT] $errMsg');
      _addEvent(MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.error,
        topic: topic,
        description: errMsg,
      ));
      _pushState(_state.copyWith(error: errMsg));
      return false;
    }
  }

  Future<bool> publish(
    String topic,
    String payload, {
    int qos = 0,
    bool retain = false,
  }) async {
    if (!isConnected) return false;
    try {
      final builder = MqttClientPayloadBuilder()..addString(payload);
      _client!.publishMessage(
        topic,
        MqttQos.values[qos.clamp(0, 2)],
        builder.payload!,
        retain: retain,
      );
      _addMessage(MQTTMessage(
        topic: topic,
        payload: payload,
        timestamp: DateTime.now(),
        isIncoming: false,
      ));
      _addEvent(MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.send,
        topic: topic,
        payload: payload,
        description: 'Message sent to $topic',
      ));
      return true;
    } catch (e) {
      final errMsg = 'Publish error: $e';
      _log.e('[MQTT] $errMsg');
      _addEvent(MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.error,
        topic: topic,
        description: errMsg,
      ));
      _pushState(_state.copyWith(error: errMsg));
      return false;
    }
  }

  void dispose() {
    disconnect();
    _stateController.close();
  }
}
