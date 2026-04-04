import 'package:apidash_design_system/apidash_design_system.dart';
import 'package:flutter/material.dart';
import 'package:apidash/consts.dart';
import 'package:apidash/models/mqtt_request_model.dart';
import 'package:apidash/models/websocket_request_model.dart';
import 'package:apidash/models/grpc_request_model.dart';
import 'package:apidash/widgets/previewer_codegen.dart';
import 'package:apidash/widgets/button_copy.dart';
import 'package:apidash/widgets/button_save_download.dart';
import 'package:apidash/widgets/button_share.dart';
import 'package:apidash/utils/utils.dart';

// ──────────────────────────────────────────────────────────────────────────────
// WebSocket Code Generator
// ──────────────────────────────────────────────────────────────────────────────

String generateWebSocketCode(
  WebSocketRequestModel model,
  WSLang lang,
) {
  final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;
  final headers = (model.requestHeaders ?? [])
      .asMap()
      .entries
      .where((e) =>
          model.isHeaderEnabledList == null ||
          (model.isHeaderEnabledList!.length > e.key &&
              model.isHeaderEnabledList![e.key]))
      .map((e) => e.value)
      .where((h) => h.name.isNotEmpty)
      .toList();

  switch (lang) {
    case WSLang.javascript:
      final buf = StringBuffer();
      buf.writeln('// WebSocket Client - JavaScript');
      buf.writeln('const socket = new WebSocket("$url");');
      buf.writeln('');
      buf.writeln('socket.addEventListener("open", (event) => {');
      buf.writeln('  console.log("Connected to WebSocket server");');
      buf.writeln('  // socket.send("Hello Server!");');
      buf.writeln('});');
      buf.writeln('');
      buf.writeln('socket.addEventListener("message", (event) => {');
      buf.writeln('  console.log("Message from server:", event.data);');
      buf.writeln('});');
      buf.writeln('');
      buf.writeln('socket.addEventListener("close", (event) => {');
      buf.writeln('  console.log("Connection closed:", event.code, event.reason);');
      buf.writeln('});');
      buf.writeln('');
      buf.writeln('socket.addEventListener("error", (event) => {');
      buf.writeln('  console.error("WebSocket error:", event);');
      buf.writeln('});');
      return buf.toString();

    case WSLang.python:
      final buf = StringBuffer();
      buf.writeln('# WebSocket Client - Python (websockets library)');
      buf.writeln('# pip install websockets');
      buf.writeln('');
      buf.writeln('import asyncio');
      buf.writeln('import websockets');
      buf.writeln('');
      if (headers.isNotEmpty) {
        buf.writeln('HEADERS = {');
        for (final h in headers) {
          buf.writeln('    "${h.name}": "${h.value}",');
        }
        buf.writeln('}');
        buf.writeln('');
      }
      buf.writeln('async def main():');
      final headerArg = headers.isNotEmpty ? ', extra_headers=HEADERS' : '';
      buf.writeln('    async with websockets.connect("$url"$headerArg) as ws:');
      buf.writeln('        print("Connected to WebSocket server")');
      buf.writeln('        # await ws.send("Hello Server!")');
      buf.writeln('        async for message in ws:');
      buf.writeln('            print(f"Received: {message}")');
      buf.writeln('');
      buf.writeln('asyncio.run(main())');
      return buf.toString();

    case WSLang.dart:
      final buf = StringBuffer();
      buf.writeln('// WebSocket Client - Dart');
      buf.writeln("import 'dart:io';");
      buf.writeln('');
      buf.writeln('Future<void> main() async {');
      buf.writeln('  final socket = await WebSocket.connect("$url");');
      buf.writeln('  print("Connected to WebSocket server");');
      buf.writeln('');
      buf.writeln('  socket.listen(');
      buf.writeln('    (data) => print("Received: \$data"),');
      buf.writeln('    onDone: () => print("Connection closed"),');
      buf.writeln('    onError: (err) => print("Error: \$err"),');
      buf.writeln('  );');
      buf.writeln('');
      buf.writeln('  // socket.add("Hello Server!");');
      buf.writeln('  // socket.close();');
      buf.writeln('}');
      return buf.toString();

    case WSLang.nodejs:
      final buf = StringBuffer();
      buf.writeln('// WebSocket Client - Node.js (ws library)');
      buf.writeln('// npm install ws');
      buf.writeln('');
      buf.writeln("const WebSocket = require('ws');");
      buf.writeln('');
      final opts = headers.isNotEmpty
          ? ', { headers: ${_jsHeaders(headers)} }'
          : '';
      buf.writeln('const ws = new WebSocket("$url"$opts);');
      buf.writeln('');
      buf.writeln("ws.on('open', () => {");
      buf.writeln("  console.log('Connected to WebSocket server');");
      buf.writeln("  // ws.send('Hello Server!');");
      buf.writeln('});');
      buf.writeln('');
      buf.writeln("ws.on('message', (data) => {");
      buf.writeln("  console.log('Received:', data.toString());");
      buf.writeln('});');
      buf.writeln('');
      buf.writeln("ws.on('close', (code, reason) => {");
      buf.writeln("  console.log('Connection closed:', code, reason.toString());");
      buf.writeln('});');
      buf.writeln('');
      buf.writeln("ws.on('error', (err) => console.error('Error:', err));");
      return buf.toString();
  }
}

String _jsHeaders(List<dynamic> headers) {
  final parts = headers.map((h) => '"${h.name}": "${h.value}"').join(', ');
  return '{ $parts }';
}

// ──────────────────────────────────────────────────────────────────────────────
// MQTT Code Generator
// ──────────────────────────────────────────────────────────────────────────────

String generateMQTTCode(MQTTRequestModel model, MQTTLang lang) {
  final broker = model.brokerUrl.isEmpty ? 'broker.mosquitto.org' : model.brokerUrl;
  final port = model.port;
  final clientId = model.clientId.isEmpty ? 'apidash_client' : model.clientId;
  final username = model.username;
  final password = model.password;
  final topics = model.topics.where((t) => t.topic.isNotEmpty).toList();
  final pubTopic = model.publishTopic.isEmpty ? 'apidash/test' : model.publishTopic;
  final pubPayload = model.publishPayload.isEmpty ? 'Hello from apidash!' : model.publishPayload;
  final protocol = model.protocolVersion == MQTTProtocolVersion.v5 ? 5 : 4;
  final tls = model.useTls;
  final scheme = tls ? (port == 443 ? 'wss' : 'mqtts') : 'mqtt';

  switch (lang) {
    case MQTTLang.python:
      final buf = StringBuffer();
      buf.writeln('# MQTT Client - Python (paho-mqtt)');
      buf.writeln('# pip install paho-mqtt');
      buf.writeln('');
      buf.writeln('import paho.mqtt.client as mqtt');
      buf.writeln('');
      if (topics.isNotEmpty) {
        buf.writeln('TOPICS = [');
        for (final t in topics) {
          buf.writeln('    ("${t.topic}", ${t.qos}),');
        }
        buf.writeln(']');
        buf.writeln('');
      }
      buf.writeln('def on_connect(client, userdata, flags, rc, properties=None):');
      buf.writeln('    print(f"Connected with result code {rc}")');
      if (topics.isNotEmpty) {
        buf.writeln('    for topic, qos in TOPICS:');
        buf.writeln('        client.subscribe(topic, qos)');
      }
      buf.writeln('');
      buf.writeln('def on_message(client, userdata, msg):');
      buf.writeln('    print(f"[{msg.topic}] {msg.payload.decode()}")');
      buf.writeln('');
      buf.writeln('client = mqtt.Client(');
      buf.writeln('    client_id="$clientId",');
      buf.writeln('    protocol=mqtt.MQTTv${protocol == 5 ? "5" : "311"},');
      buf.writeln(')');
      buf.writeln('client.on_connect = on_connect');
      buf.writeln('client.on_message = on_message');
      if (username.isNotEmpty) {
        buf.writeln('client.username_pw_set("$username", "$password")');
      }
      if (tls) {
        buf.writeln('client.tls_set()  # Configure TLS');
      }
      buf.writeln('');
      buf.writeln('client.connect("$broker", $port, ${model.keepAlive})');
      buf.writeln('client.loop_start()');
      buf.writeln('');
      buf.writeln('# Publish a message');
      buf.writeln('client.publish("$pubTopic", "$pubPayload", qos=${model.publishQos})');
      buf.writeln('');
      buf.writeln('# client.loop_forever()  # Block until disconnect');
      return buf.toString();

    case MQTTLang.javascript:
      final buf = StringBuffer();
      buf.writeln('// MQTT Client - JavaScript (mqtt.js)');
      buf.writeln('// npm install mqtt');
      buf.writeln('');
      buf.writeln("const mqtt = require('mqtt');");
      buf.writeln('');
      buf.writeln('const options = {');
      buf.writeln('  clientId: "$clientId",');
      if (username.isNotEmpty) {
        buf.writeln('  username: "$username",');
        buf.writeln('  password: "$password",');
      }
      buf.writeln('  keepalive: ${model.keepAlive},');
      buf.writeln('  clean: ${model.cleanSession},');
      buf.writeln('  protocolVersion: $protocol,');
      buf.writeln('};');
      buf.writeln('');
      buf.writeln('const client = mqtt.connect("$scheme://$broker:$port", options);');
      buf.writeln('');
      buf.writeln("client.on('connect', () => {");
      buf.writeln("  console.log('Connected to MQTT broker');");
      if (topics.isNotEmpty) {
        for (final t in topics) {
          buf.writeln('  client.subscribe("${t.topic}", { qos: ${t.qos} });');
        }
      }
      buf.writeln('  client.publish("$pubTopic", "$pubPayload", { qos: ${model.publishQos} });');
      buf.writeln('});');
      buf.writeln('');
      buf.writeln("client.on('message', (topic, message) => {");
      buf.writeln("  console.log(`[\${topic}] \${message.toString()}`);");
      buf.writeln('});');
      buf.writeln('');
      buf.writeln("client.on('error', (err) => console.error('MQTT Error:', err));");
      return buf.toString();

    case MQTTLang.dart:
      final buf = StringBuffer();
      buf.writeln('// MQTT Client - Dart (mqtt_client)');
      buf.writeln('// dart pub add mqtt_client');
      buf.writeln('');
      buf.writeln("import 'package:mqtt_client/mqtt_client.dart';");
      buf.writeln("import 'package:mqtt_client/mqtt_server_client.dart';");
      buf.writeln('');
      buf.writeln('Future<void> main() async {');
      buf.writeln('  final client = MqttServerClient("$broker", "$clientId")');
      buf.writeln('    ..port = $port');
      buf.writeln('    ..keepAlivePeriod = ${model.keepAlive}');
      if (tls) {
        buf.writeln('    ..secure = true');
      }
      buf.writeln('    ..logging(on: false);');
      buf.writeln('');
      buf.writeln('  final connMsg = MqttConnectMessage()');
      buf.writeln('      .withClientIdentifier("$clientId")');
      if (model.cleanSession) {
        buf.writeln('      .startClean()');
      }
      buf.writeln('      .withWillQos(MqttQos.atMostOnce);');
      buf.writeln('  client.connectionMessage = connMsg;');
      buf.writeln('');
      if (username.isNotEmpty) {
        buf.writeln('  client.connectionMessage!');
        buf.writeln('      .authenticateAs("$username", "$password");');
        buf.writeln('');
      }
      buf.writeln('  await client.connect();');
      buf.writeln('');
      if (topics.isNotEmpty) {
        for (final t in topics) {
          final qos = t.qos == 2 ? 'exactlyOnce' : t.qos == 1 ? 'atLeastOnce' : 'atMostOnce';
          buf.writeln('  client.subscribe("${t.topic}", MqttQos.$qos);');
        }
        buf.writeln('');
        buf.writeln('  client.updates!.listen((messages) {');
        buf.writeln('    final msg = messages[0];');
        buf.writeln('    final payload = msg.payload as MqttPublishMessage;');
        buf.writeln('    final data = MqttPublishPayload.bytesToStringAsString(payload.payload.message);');
        buf.writeln('    print("[\${msg.topic}] \$data");');
        buf.writeln('  });');
        buf.writeln('');
      }
      buf.writeln('  // Publish a message');
      buf.writeln('  final builder = MqttClientPayloadBuilder()..addString("$pubPayload");');
      buf.writeln('  client.publishMessage("$pubTopic", MqttQos.atMostOnce, builder.payload!);');
      buf.writeln('}');
      return buf.toString();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// gRPC Code Generator
// ──────────────────────────────────────────────────────────────────────────────

String generateGrpcCode(GrpcRequestModel model, GrpcLang lang) {
  final url = model.url.isEmpty ? 'localhost:50051' : model.url;
  // strip leading scheme if present
  final host = url.replaceFirst(RegExp(r'^https?://'), '');
  final serviceName = model.serviceName.isEmpty ? 'YourService' : model.serviceName;
  final methodName = model.methodName.isEmpty ? 'YourMethod' : model.methodName;
  final payload = model.requestJson.isEmpty ? '{}' : model.requestJson;
  final metadata = model.metadata.asMap().entries
      .where((e) =>
          model.isMetadataEnabledList.length > e.key &&
          model.isMetadataEnabledList[e.key])
      .map((e) => e.value)
      .where((m) => m.name.isNotEmpty)
      .toList();
  final tls = model.useTls;

  switch (lang) {
    case GrpcLang.python:
      final buf = StringBuffer();
      buf.writeln('# gRPC Client - Python');
      buf.writeln('# pip install grpcio grpcio-tools');
      buf.writeln('');
      buf.writeln('import grpc');
      buf.writeln("# from your_proto_pb2_grpc import ${serviceName}Stub");
      buf.writeln("# from your_proto_pb2 import ${methodName}Request");
      buf.writeln('');
      buf.writeln('def main():');
      if (tls) {
        buf.writeln('    credentials = grpc.ssl_channel_credentials()');
        buf.writeln('    channel = grpc.secure_channel("$host", credentials)');
      } else {
        buf.writeln('    channel = grpc.insecure_channel("$host")');
      }
      buf.writeln('    # stub = ${serviceName}Stub(channel)');
      buf.writeln('');
      if (metadata.isNotEmpty) {
        buf.writeln('    metadata = [');
        for (final m in metadata) {
          buf.writeln('        ("${m.name}", "${m.value}"),');
        }
        buf.writeln('    ]');
        buf.writeln('');
        buf.writeln('    # response = stub.$methodName(${methodName}Request(), metadata=metadata)');
      } else {
        buf.writeln('    # request = ${methodName}Request()');
        buf.writeln('    # response = stub.$methodName(request)');
      }
      buf.writeln('    # print(response)');
      buf.writeln('');
      buf.writeln('    # Request JSON payload:');
      for (final line in payload.split('\n')) {
        buf.writeln('    # $line');
      }
      buf.writeln('');
      buf.writeln('if __name__ == "__main__":');
      buf.writeln('    main()');
      return buf.toString();

    case GrpcLang.javascript:
      final buf = StringBuffer();
      buf.writeln('// gRPC Client - JavaScript (Node.js)');
      buf.writeln('// npm install @grpc/grpc-js @grpc/proto-loader');
      buf.writeln('');
      buf.writeln("const grpc = require('@grpc/grpc-js');");
      buf.writeln("const protoLoader = require('@grpc/proto-loader');");
      buf.writeln('');
      buf.writeln("const PROTO_PATH = './your_service.proto';");
      buf.writeln('');
      buf.writeln('const packageDef = protoLoader.loadSync(PROTO_PATH, {');
      buf.writeln('  keepCase: true,');
      buf.writeln('  longs: String,');
      buf.writeln('  defaults: true,');
      buf.writeln('});');
      buf.writeln('const protoDescriptor = grpc.loadPackageDefinition(packageDef);');
      buf.writeln('');
      final creds = tls
          ? 'grpc.credentials.createSsl()'
          : 'grpc.credentials.createInsecure()';
      buf.writeln('// const client = new protoDescriptor.$serviceName(');
      buf.writeln('//   "$host",');
      buf.writeln('//   $creds');
      buf.writeln('// );');
      buf.writeln('');
      if (metadata.isNotEmpty) {
        buf.writeln('const meta = new grpc.Metadata();');
        for (final m in metadata) {
          buf.writeln('meta.add("${m.name}", "${m.value}");');
        }
        buf.writeln('');
      }
      buf.writeln('// Request payload:');
      buf.writeln('// const request = $payload;');
      buf.writeln('');
      final metaArg = metadata.isNotEmpty ? 'request, meta,' : 'request,';
      buf.writeln('// client.$methodName($metaArg (err, response) => {');
      buf.writeln('//   if (err) console.error(err);');
      buf.writeln('//   else console.log(response);');
      buf.writeln('// });');
      return buf.toString();

    case GrpcLang.dart:
      final buf = StringBuffer();
      buf.writeln('// gRPC Client - Dart');
      buf.writeln('// dart pub add grpc protobuf');
      buf.writeln('');
      buf.writeln("import 'package:grpc/grpc.dart';");
      buf.writeln('');
      buf.writeln('Future<void> main() async {');
      final parts = host.split(':');
      final hostOnly = parts[0];
      final portOnly = parts.length > 1 ? parts[1] : (tls ? '443' : '50051');
      buf.writeln('  final channel = ClientChannel(');
      buf.writeln('    "$hostOnly",');
      buf.writeln('    port: $portOnly,');
      buf.writeln('    options: ChannelOptions(');
      if (tls) {
        buf.writeln('      credentials: ChannelCredentials.secure(),');
      } else {
        buf.writeln('      credentials: ChannelCredentials.insecure(),');
      }
      buf.writeln('    ),');
      buf.writeln('  );');
      buf.writeln('');
      if (metadata.isNotEmpty) {
        buf.writeln('  final options = CallOptions(metadata: {');
        for (final m in metadata) {
          buf.writeln('    "${m.name}": "${m.value}",');
        }
        buf.writeln('  });');
        buf.writeln('');
      }
      buf.writeln('  // final stub = ${serviceName}Client(channel);');
      buf.writeln('  // final response = await stub.$methodName(');
      buf.writeln('  //   ${methodName}Request()..mergeFromProto3Json($payload),');
      if (metadata.isNotEmpty) {
        buf.writeln('  //   options: options,');
      }
      buf.writeln('  // );');
      buf.writeln('  // print(response);');
      buf.writeln('');
      buf.writeln('  await channel.shutdown();');
      buf.writeln('}');
      return buf.toString();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Enums for supported languages per protocol
// ──────────────────────────────────────────────────────────────────────────────

enum WSLang { javascript, nodejs, python, dart }

enum MQTTLang { python, javascript, dart }

enum GrpcLang { python, javascript, dart }

// ──────────────────────────────────────────────────────────────────────────────
// Widget: WebSocketCodePane
// ──────────────────────────────────────────────────────────────────────────────

class WebSocketCodePane extends StatefulWidget {
  const WebSocketCodePane({super.key, required this.model});
  final WebSocketRequestModel model;

  @override
  State<WebSocketCodePane> createState() => _WebSocketCodePaneState();
}

class _WebSocketCodePaneState extends State<WebSocketCodePane> {
  WSLang _lang = WSLang.javascript;

  @override
  Widget build(BuildContext context) {
    final code = generateWebSocketCode(widget.model, _lang);
    return _ProtocolCodeView(
      code: code,
      highlightLang: _lang == WSLang.python ? 'python' : 'javascript',
      ext: _lang == WSLang.python
          ? 'py'
          : (_lang == WSLang.dart ? 'dart' : 'js'),
      langSelector: Expanded(
        child: ADDropdownButton<WSLang>(
          value: _lang,
          values: const [
            (WSLang.javascript, 'JavaScript (Browser)'),
            (WSLang.nodejs, 'Node.js (ws)'),
            (WSLang.python, 'Python (websockets)'),
            (WSLang.dart, 'Dart'),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _lang = v);
          },
          iconSize: 16,
          isExpanded: true,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widget: MQTTCodePane
// ──────────────────────────────────────────────────────────────────────────────

class MQTTCodePane extends StatefulWidget {
  const MQTTCodePane({super.key, required this.model});
  final MQTTRequestModel model;

  @override
  State<MQTTCodePane> createState() => _MQTTCodePaneState();
}

class _MQTTCodePaneState extends State<MQTTCodePane> {
  MQTTLang _lang = MQTTLang.python;

  @override
  Widget build(BuildContext context) {
    final code = generateMQTTCode(widget.model, _lang);
    return _ProtocolCodeView(
      code: code,
      highlightLang: _lang == MQTTLang.dart
          ? 'dart'
          : (_lang == MQTTLang.python ? 'python' : 'javascript'),
      ext: _lang == MQTTLang.python
          ? 'py'
          : (_lang == MQTTLang.dart ? 'dart' : 'js'),
      langSelector: Expanded(
        child: ADDropdownButton<MQTTLang>(
          value: _lang,
          values: const [
            (MQTTLang.python, 'Python (paho-mqtt)'),
            (MQTTLang.javascript, 'JavaScript (mqtt.js)'),
            (MQTTLang.dart, 'Dart (mqtt_client)'),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _lang = v);
          },
          iconSize: 16,
          isExpanded: true,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widget: GrpcCodePane
// ──────────────────────────────────────────────────────────────────────────────

class GrpcCodePane extends StatefulWidget {
  const GrpcCodePane({super.key, required this.model});
  final GrpcRequestModel model;

  @override
  State<GrpcCodePane> createState() => _GrpcCodePaneState();
}

class _GrpcCodePaneState extends State<GrpcCodePane> {
  GrpcLang _lang = GrpcLang.python;

  @override
  Widget build(BuildContext context) {
    final code = generateGrpcCode(widget.model, _lang);
    return _ProtocolCodeView(
      code: code,
      highlightLang: _lang == GrpcLang.dart
          ? 'dart'
          : (_lang == GrpcLang.python ? 'python' : 'javascript'),
      ext: _lang == GrpcLang.python
          ? 'py'
          : (_lang == GrpcLang.dart ? 'dart' : 'js'),
      langSelector: Expanded(
        child: ADDropdownButton<GrpcLang>(
          value: _lang,
          values: const [
            (GrpcLang.python, 'Python (grpcio)'),
            (GrpcLang.javascript, 'JavaScript (@grpc/grpc-js)'),
            (GrpcLang.dart, 'Dart (grpc)'),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _lang = v);
          },
          iconSize: 16,
          isExpanded: true,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared layout widget
// ──────────────────────────────────────────────────────────────────────────────

class _ProtocolCodeView extends StatelessWidget {
  const _ProtocolCodeView({
    required this.code,
    required this.highlightLang,
    required this.ext,
    required this.langSelector,
  });

  final String code;
  final String highlightLang;
  final String ext;
  final Widget langSelector;

  @override
  Widget build(BuildContext context) {
    final codeTheme = Theme.of(context).brightness == Brightness.light
        ? kLightCodeTheme
        : kDarkCodeTheme;
    final textContainerdecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest),
      borderRadius: kBorderRadius8,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var showLabel = showButtonLabelsInViewCodePane(
          constraints.maxWidth,
        );
        return Padding(
          padding: kP10,
          child: Column(
            children: [
              SizedBox(
                height: kHeaderHeight,
                child: Row(
                  children: [
                    langSelector,
                    CopyButton(
                      toCopy: code,
                      showLabel: showLabel,
                    ),
                    kIsMobile
                        ? ShareButton(
                            toShare: code,
                            showLabel: showLabel,
                          )
                        : SaveInDownloadsButton(
                            content: stringToBytes(code),
                            ext: ext,
                            showLabel: showLabel,
                          ),
                  ],
                ),
              ),
              kVSpacer10,
              Expanded(
                child: Container(
                  width: double.maxFinite,
                  padding: kP8,
                  decoration: textContainerdecoration,
                  child: CodeGenPreviewer(
                    code: code,
                    theme: codeTheme,
                    language: highlightLang,
                    textStyle: kCodeStyle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
