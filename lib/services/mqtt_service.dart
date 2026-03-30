import 'dart:async';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt3;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt3_server;
import 'package:mqtt5_client/mqtt5_client.dart' as mqtt5;
import 'package:mqtt5_client/mqtt5_server_client.dart' as mqtt5_server;
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
  final int qos; // 0, 1, or 2
  final bool isRetained; // broker-flagged retained

  // --- NEW FIELDS FOR RAW PROTOCOL VIEW ---
  final int? packetTypeByte; 
  final bool dupFlag;
  final Uint8List? topicBytes;
  final Uint8List? payloadBytes;

  const MQTTMessage({
    required this.topic,
    required this.payload,
    required this.timestamp,
    required this.isIncoming,
    this.qos = 0,
    this.isRetained = false,
    this.packetTypeByte,
    this.dupFlag = false,
    this.topicBytes,
    this.payloadBytes,
  });
}

class MQTTConnectionState {
  final bool isConnected;
  final bool isReconnecting;
  final String? error;
  final DateTime? connectedAt;
  final List<MQTTMessage> messages;
  final List<MQTTEvent> eventLog;

  const MQTTConnectionState({
    this.isConnected = false,
    this.isReconnecting = false,
    this.error,
    this.connectedAt,
    this.messages = const [],
    this.eventLog = const [],
  });

  MQTTConnectionState copyWith({
    bool? isConnected,
    bool? isReconnecting,
    String? error,
    DateTime? connectedAt,
    List<MQTTMessage>? messages,
    List<MQTTEvent>? eventLog,
  }) {
    return MQTTConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      error: error ?? this.error,
      connectedAt: connectedAt ?? this.connectedAt,
      messages: messages ?? this.messages,
      eventLog: eventLog ?? this.eventLog,
    );
  }
}

// ─── MQTT Service ─────────────────────────────────────────────────────────────

class MQTTService {
  mqtt3_server.MqttServerClient? _clientV3;
  mqtt5_server.MqttServerClient? _clientV5;

  MQTTConnectionState _state = const MQTTConnectionState();
  final _stateController = StreamController<MQTTConnectionState>.broadcast();
  final _messages = <MQTTMessage>[];
  final _eventLog = <MQTTEvent>[];
  StreamSubscription? _updatesSub;

  Stream<MQTTConnectionState> get stateStream => _stateController.stream;
  MQTTConnectionState get currentState => _state;

  bool get isConnected =>
      _clientV5?.connectionStatus?.state ==
          mqtt5.MqttConnectionState.connected ||
      _clientV3?.connectionStatus?.state == mqtt3.MqttConnectionState.connected;

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
    _addEvent(
      MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.connect,
        description: 'Connected to broker',
      ),
    );
    _pushState(
      _state.copyWith(
        isConnected: true,
        connectedAt: DateTime.now(),
        error: null,
      ),
    );
  }

  void _onDisconnected() {
    _log.i('[MQTT] Disconnected from broker');
    _addEvent(
      MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.disconnect,
        description: 'Disconnected from broker',
      ),
    );
    _pushState(_state.copyWith(isConnected: false));
  }

  void _onSubscribed(String topic) {
    _log.i('[MQTT] Subscribed to $topic');
    _addEvent(
      MQTTEvent(
        timestamp: DateTime.now(),
        type: MQTTEventType.subscribe,
        topic: topic,
        description: 'Subscribed to topic $topic',
      ),
    );
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  Future<bool> connect(MQTTRequestModel request) async {
    _log.i('[MQTT] Connecting to ${request.brokerUrl}:${request.port}');

    // Initialize live session lists with saved history from Hive
    _messages.clear();
    _messages.addAll(
      request.savedMessages.map(
        (s) => MQTTMessage(
          topic: s.topic,
          payload: s.payload,
          timestamp: s.timestamp,
          isIncoming: s.isIncoming,
          qos: s.qos,
          isRetained: s.isRetained,
        ),
      ),
    );

    _eventLog.clear();
    _eventLog.addAll(
      request.savedEventLog.map(
        (e) => MQTTEvent(
          timestamp: e.timestamp,
          type: MQTTEventType.values.firstWhere(
            (t) => t.name == e.eventType,
            orElse: () => MQTTEventType.connect,
          ),
          topic: e.topic,
          payload: e.payload,
          description: e.description,
        ),
      ),
    );

    String brokerUrl = request.brokerUrl.trim();
    if (brokerUrl.isEmpty) {
      const errMsg = 'Connection error: Broker URL is required';
      _log.e('[MQTT] $errMsg');
      _addEvent(
        MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.error,
          description: errMsg,
        ),
      );
      _pushState(_state.copyWith(isConnected: false, error: errMsg));
      return false;
    }

    if (!brokerUrl.contains('://')) {
      brokerUrl = 'mqtt://$brokerUrl';
    }
    final uri = Uri.parse(brokerUrl);
    final isWebSocket = uri.scheme == 'ws' || uri.scheme == 'wss';
    final uniqueId = 'apidash_${DateTime.now().millisecondsSinceEpoch}';
    final clientId = request.clientId.isNotEmpty ? request.clientId : uniqueId;

    try {
      await disconnect();

      if (request.protocolVersion == MQTTProtocolVersion.v5) {
        return await _connectV5(request, uri, isWebSocket, clientId);
      } else {
        return await _connectV3(request, uri, isWebSocket, clientId);
      }
    } catch (e) {
      var errMsg = e.toString();

      if (_clientV5?.connectionStatus?.state ==
              mqtt5.MqttConnectionState.faulted &&
          _clientV5?.connectionStatus?.reasonCode != null &&
          _clientV5!.connectionStatus!.reasonCode !=
              mqtt5.MqttConnectReasonCode.success) {
        errMsg = _connackErrorV5(_clientV5!.connectionStatus);
      } else if (_clientV3?.connectionStatus?.state ==
              mqtt3.MqttConnectionState.faulted &&
          _clientV3?.connectionStatus?.returnCode != null &&
          _clientV3!.connectionStatus!.returnCode !=
              mqtt3.MqttConnectReturnCode.connectionAccepted) {
        errMsg = _connackErrorV3(_clientV3!.connectionStatus!.returnCode);
      } else if (errMsg.contains('SocketException')) {
        errMsg =
            'Connection failed: Unable to reach the broker. Check your URL and network.';
      } else if (errMsg.contains('NoConnectionException')) {
        errMsg =
            'Connection timeout: The broker did not respond. Verify the port and TLS settings.';
      } else if (errMsg.contains('HandshakeException') ||
          errMsg.contains('CERTIFICATE_VERIFY_FAILED')) {
        errMsg =
            'TLS Handshake failed: The TLS connection was rejected by the broker or network.';
      } else if (errMsg.contains('NotAuthorized') ||
          errMsg.contains('Not authorized')) {
        errMsg = 'Authentication failed: Invalid username or password.';
      } else if (errMsg.contains('CONNACK error')) {
        // Fallback if exception string already contains CONNACK error
        errMsg = errMsg.replaceAll('Bad state: ', '');
      } else {
        errMsg = 'Connection error: $errMsg';
      }

      _log.e('[MQTT] $errMsg');
      _addEvent(
        MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.error,
          description: errMsg,
        ),
      );
      _pushState(_state.copyWith(isConnected: false, error: errMsg));
      return false;
    }
  }

  Future<bool> _connectV3(
    MQTTRequestModel request,
    Uri uri,
    bool isWebSocket,
    String clientId,
  ) async {
    final client = isWebSocket
        ? (mqtt3_server.MqttServerClient(uri.toString(), clientId)
            ..useWebSocket = true
            ..port = uri.hasPort ? uri.port : 9001)
        : (mqtt3_server.MqttServerClient(uri.host, clientId)
            ..port = uri.hasPort
                ? uri.port
                : (request.port == 0 ? 1883 : request.port));

    client.connectTimeoutPeriod = 4000; // 10s timeout
    client.keepAlivePeriod = request.keepAlive;
    client.disconnectOnNoResponsePeriod = request.keepAlive > 0
        ? request.keepAlive * 2
        : 60;
    client.secure = request.useTls;
    if (request.useTls) {
      client.onBadCertificate = (dynamic cert) => true;
    }
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.autoReconnect = request.autoReconnect;
    client.onAutoReconnect = () {
      _log.i('[MQTT] Auto-reconnecting...');
      _addEvent(
        MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.disconnect,
          description: 'Connection lost. Auto-reconnecting...',
        ),
      );
      _pushState(_state.copyWith(isConnected: false, isReconnecting: true));
    };
    client.onAutoReconnected = () {
      _log.i('[MQTT] Auto-reconnected');
      _pushState(
        _state.copyWith(
          isConnected: true,
          isReconnecting: false,
          connectedAt: DateTime.now(),
          error: null,
        ),
      );
    };

    if (request.protocolVersion == MQTTProtocolVersion.v31) {
      client.setProtocolV31();
    } else {
      client.setProtocolV311();
    }

    final connMsg = mqtt3.MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillQos(mqtt3.MqttQos.atMostOnce);

    if (request.cleanSession) connMsg.startClean();

    if (request.username.isNotEmpty) {
      connMsg.authenticateAs(request.username, request.password);
    }
    client.connectionMessage = connMsg;
    _clientV3 = client;

    final status = await client.connect();
    if (status?.state != mqtt3.MqttConnectionState.connected) {
      throw StateError(_connackErrorV3(status?.returnCode));
    }

    for (final topic in request.topics.where((t) => t.subscribe)) {
      await subscribe(topic.topic, topic.qos);
    }

    _updatesSub = client.updates?.listen((messages) {
      for (final msg in messages) {
        final r = msg.payload as mqtt3.MqttPublishMessage;
        final payload = mqtt3.MqttPublishPayload.bytesToStringAsString(
          r.payload.message,
        );
        final qosVal = r.header?.qos.index ?? 0;
        final retained = r.header?.retain ?? false;
        _log.d('[MQTT] Received on ${msg.topic}: $payload');
        _addMessage(
          MQTTMessage(
            topic: msg.topic,
            payload: payload,
            timestamp: DateTime.now(),
            isIncoming: true,
            qos: qosVal.clamp(0, 2),
            isRetained: retained,
          ),
        );
        _addEvent(
          MQTTEvent(
            timestamp: DateTime.now(),
            type: MQTTEventType.receive,
            topic: msg.topic,
            payload: payload,
            description: 'Message received from ${msg.topic}',
          ),
        );
      }
    });
    return true;
  }

  Future<bool> _connectV5(
    MQTTRequestModel request,
    Uri uri,
    bool isWebSocket,
    String clientId,
  ) async {
    final client = isWebSocket
        ? (mqtt5_server.MqttServerClient(uri.toString(), clientId)
            ..useWebSocket = true
            ..port = uri.hasPort ? uri.port : 9001)
        : (mqtt5_server.MqttServerClient(uri.host, clientId)
            ..port = uri.hasPort
                ? uri.port
                : (request.port == 0 ? 1883 : request.port));

    client.keepAlivePeriod = request.keepAlive;
    client.disconnectOnNoResponsePeriod = request.keepAlive > 0
        ? request.keepAlive * 2
        : 60;
    client.secure = request.useTls;
    if (request.useTls) {
      client.onBadCertificate = (dynamic cert) => true;
    }
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.autoReconnect = request.autoReconnect;
    client.onAutoReconnect = () {
      _log.i('[MQTT] Auto-reconnecting...');
      _addEvent(
        MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.disconnect,
          description: 'Connection lost. Auto-reconnecting...',
        ),
      );
      _pushState(_state.copyWith(isConnected: false, isReconnecting: true));
    };
    client.onAutoReconnected = () {
      _log.i('[MQTT] Auto-reconnected');
      _pushState(
        _state.copyWith(
          isConnected: true,
          isReconnecting: false,
          connectedAt: DateTime.now(),
          error: null,
        ),
      );
    };

    final connMsg = mqtt5.MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillQos(mqtt5.MqttQos.atMostOnce);

    if (request.cleanSession) connMsg.startClean();

    if (request.username.isNotEmpty) {
      connMsg.authenticateAs(request.username, request.password);
    }
    client.connectionMessage = connMsg;
    _clientV5 = client;

    final status = await client.connect();
    if (status?.state != mqtt5.MqttConnectionState.connected) {
      throw StateError(_connackErrorV5(status));
    }

    for (final topic in request.topics.where((t) => t.subscribe)) {
      await subscribe(topic.topic, topic.qos);
    }

    _updatesSub = client.updates.listen((messages) {
      for (final msg in messages) {
        final r = msg.payload as mqtt5.MqttPublishMessage;
        final pb = r.payload.message;
        final payload = pb == null
            ? ''
            : mqtt5.MqttPublishPayload.bytesToStringAsString(pb);
        final qosVal = r.header?.qos.index ?? 0;
        final retained = r.header?.retain ?? false;
        _log.d('[MQTT] Received on ${msg.topic}: $payload');
        _addMessage(
          MQTTMessage(
            topic: msg.topic ?? '',
            payload: payload,
            timestamp: DateTime.now(),
            isIncoming: true,
            qos: qosVal.clamp(0, 2),
            isRetained: retained,
          ),
        );
        _addEvent(
          MQTTEvent(
            timestamp: DateTime.now(),
            type: MQTTEventType.receive,
            topic: msg.topic,
            payload: payload,
            description: 'Message received from ${msg.topic}',
          ),
        );
      }
    });
    return true;
  }

  Future<void> disconnect() async {
    await _updatesSub?.cancel();
    _updatesSub = null;

    // Always call disconnect on both clients if they exist,
    // regardless of the isConnected state to clean up zombies.
    _clientV5?.disconnect();
    _clientV3?.disconnect();

    _clientV5 = null;
    _clientV3 = null;
    _pushState(const MQTTConnectionState());
  }

  Future<bool> subscribe(String topic, int qos) async {
    if (!isConnected) return false;
    try {
      if (_clientV5 != null) {
        _clientV5!.subscribe(topic, mqtt5.MqttQos.values[qos.clamp(0, 2)]);
      } else {
        _clientV3!.subscribe(topic, mqtt3.MqttQos.values[qos.clamp(0, 2)]);
      }
      _onSubscribed(topic);
      return true;
    } catch (e) {
      final errMsg = 'Subscribe error: $e';
      _log.e('[MQTT] $errMsg');
      _addEvent(
        MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.error,
          topic: topic,
          description: errMsg,
        ),
      );
      _pushState(_state.copyWith(error: errMsg));
      return false;
    }
  }

  Future<bool> unsubscribe(String topic) async {
    if (!isConnected) return false;
    try {
      _clientV5?.unsubscribeStringTopic(topic);
      _clientV3?.unsubscribe(topic);

      _addEvent(
        MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.unsubscribe,
          topic: topic,
          description: 'Unsubscribed from $topic',
        ),
      );
      return true;
    } catch (e) {
      final errMsg = 'Unsubscribe error: $e';
      _log.e('[MQTT] $errMsg');
      _addEvent(
        MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.error,
          topic: topic,
          description: errMsg,
        ),
      );
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
      if (_clientV5 != null) {
        final builder = mqtt5.MqttPayloadBuilder()..addString(payload);
        _clientV5!.publishMessage(
          topic,
          mqtt5.MqttQos.values[qos.clamp(0, 2)],
          builder.payload!,
          retain: retain,
        );
      } else {
        final builder = mqtt3.MqttClientPayloadBuilder()..addString(payload);
        _clientV3!.publishMessage(
          topic,
          mqtt3.MqttQos.values[qos.clamp(0, 2)],
          builder.payload!,
          retain: retain,
        );
      }
      _addMessage(
        MQTTMessage(
          topic: topic,
          payload: payload,
          timestamp: DateTime.now(),
          isIncoming: false,
          qos: qos.clamp(0, 2),
          isRetained: retain,
        ),
      );
      _addEvent(
        MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.send,
          topic: topic,
          payload: payload,
          description: 'Message sent to $topic',
        ),
      );
      return true;
    } catch (e) {
      final errMsg = 'Publish error: $e';
      _log.e('[MQTT] $errMsg');
      _addEvent(
        MQTTEvent(
          timestamp: DateTime.now(),
          type: MQTTEventType.error,
          topic: topic,
          description: errMsg,
        ),
      );
      _pushState(_state.copyWith(error: errMsg));
      return false;
    }
  }

  void dispose() {
    disconnect();
    _stateController.close();
  }

  static String _connackErrorV3(mqtt3.MqttConnectReturnCode? code) {
    return switch (code) {
      mqtt3.MqttConnectReturnCode.unacceptedProtocolVersion =>
        'CONNACK error: Unaccepted protocol version',
      mqtt3.MqttConnectReturnCode.identifierRejected =>
        'CONNACK error: Client identifier rejected',
      mqtt3.MqttConnectReturnCode.brokerUnavailable =>
        'CONNACK error: Broker unavailable',
      mqtt3.MqttConnectReturnCode.badUsernameOrPassword =>
        'CONNACK error: Bad username or password (code 4)',
      mqtt3.MqttConnectReturnCode.notAuthorized =>
        'CONNACK error: Not authorized (code 5)',
      _ => 'CONNACK error: Connection refused (code ${code?.index})',
    };
  }

  static String _connackErrorV5(mqtt5.MqttConnectionStatus? status) {
    final reason = mqtt5.MqttConnectReasonCodeSupport.mqttConnectReasonCode
        .asString(status?.reasonCode);
    final reasonString = status?.reasonString;
    if (reasonString == null || reasonString.isEmpty) {
      return 'CONNACK error: $reason';
    }
    return 'CONNACK error: $reason ($reasonString)';
  }
}
