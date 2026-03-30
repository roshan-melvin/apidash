import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/mqtt_service.dart';

class MqttPacketInspector extends StatefulWidget {
  final MQTTMessage message;

  const MqttPacketInspector({super.key, required this.message});

  @override
  State<MqttPacketInspector> createState() => _MqttPacketInspectorState();
}

class _MqttPacketInspectorState extends State<MqttPacketInspector> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getPacketTypeName(int? byte, int qos) {
    if (byte != null) {
      final typeNumber = (byte >> 4) & 0x0F;
      if (typeNumber == 3) {
        return "PUBLISH (0x${byte.toRadixString(16).padLeft(2, '0').toUpperCase()})";
      }
      switch (typeNumber) {
        case 1: return "CONNECT (0x10)";
        case 2: return "CONNACK (0x20)";
        case 4: return "PUBACK (0x40)";
        case 5: return "PUBREC (0x50)";
        case 6: return "PUBREL (0x60)";
        case 7: return "PUBCOMP (0x70)";
        case 8: return "SUBSCRIBE (0x80)";
        case 9: return "SUBACK (0x90)";
        case 10: return "UNSUBSCRIBE (0xA0)";
        case 11: return "UNSUBACK (0xB0)";
        case 12: return "PINGREQ (0xC0)";
        case 13: return "PINGRESP (0xD0)";
        case 14: return "DISCONNECT (0xE0)";
        default: return "Unknown (0x${typeNumber.toRadixString(16).toUpperCase()})";
      }
    }
    // Default fallback for PUBLISH since all list items are PUBLISH
    final typeByte = 0x30 | (qos << 1);
    return "PUBLISH (0x${typeByte.toRadixString(16).padLeft(2, '0').toUpperCase()})";
  }

  String _detectFormat(Uint8List bytes) {
    if (bytes.isEmpty) return "Empty";
    try {
      final str = utf8.decode(bytes); // if valid UTF-8
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map || decoded is List) return "JSON";
      } catch (_) {}
      return "UTF-8 Text";
    } catch (_) {
      return "Binary";
    }
  }

  String _getUtf8Text(String payload) {
    if (payload.isEmpty) return "";
    try {
      final str = payload;
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map || decoded is List) {
          return const JsonEncoder.withIndent('  ').convert(decoded);
        }
      } catch (_) {}
      return str;
    } catch (_) {
      return "Invalid UTF-8 sequence / Binary data";
    }
  }

  int _getRemainingLengthFieldSize(int length) {
    if (length < 128) return 1;
    if (length < 16384) return 2;
    if (length < 2097152) return 3;
    return 4;
  }

  Widget _buildPropertyRow(String label, String value, ColorScheme clr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              color: clr.outline,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: clr.onSurface,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final msg = widget.message;
    
    // Fallback encoding if raw bytes aren't injected yet by the service layer
    final pBytes = msg.payloadBytes ?? Uint8List.fromList(utf8.encode(msg.payload));
    final tBytesLength = msg.topicBytes?.length ?? utf8.encode(msg.topic).length;
    
    final payloadLength = pBytes.length;
    final packetIdLength = (msg.qos > 0) ? 2 : 0;
    // 2 bytes for topic length prefix
    final remainingLength = 2 + tBytesLength + payloadLength + packetIdLength; 
    final rmLengthHex = "0x${remainingLength.toRadixString(16).toUpperCase()}";
    
    final rmFieldValueSize = _getRemainingLengthFieldSize(remainingLength);
    final totalPacketSize = 1 + rmFieldValueSize + remainingLength;

    return Container(
      decoration: BoxDecoration(
        color: clr.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: clr.outlineVariant.withAlpha(60)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Fixed Header ──
          Text("Fixed Header", style: TextStyle(color: clr.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 24,
            children: [
              _buildPropertyRow("Type", _getPacketTypeName(msg.packetTypeByte, msg.qos), clr),
              _buildPropertyRow("QoS", msg.qos.toString(), clr),
              _buildPropertyRow("Retain", msg.isRetained.toString(), clr),
              _buildPropertyRow("DUP", msg.dupFlag.toString(), clr),
            ],
          ),
          _buildPropertyRow("Remaining Length", "$remainingLength bytes ($rmLengthHex)", clr),
          const SizedBox(height: 12),
          
          // ── Variable Header ──
          Text("Variable Header", style: TextStyle(color: clr.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 24,
            children: [
              _buildPropertyRow("Topic", '"${msg.topic}"', clr),
              _buildPropertyRow("Length", "$tBytesLength bytes", clr),
              _buildPropertyRow("Packet ID", (msg.qos > 0) ? "Auto" : "N/A", clr),
            ],
          ),
          const SizedBox(height: 16),

          // ── Payload Section ──
          Text("Detected Format: ${_detectFormat(pBytes)}", 
            style: TextStyle(color: clr.primary, fontSize: 12, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: clr.primary,
            unselectedLabelColor: clr.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(height: 32, text: "HEX"),
              Tab(height: 32, text: "UTF-8"),
              Tab(height: 32, text: "Base64"),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                return IndexedStack(
                  index: _tabController.index,
                  children: [
                    HexDumpViewer(data: pBytes),
                    
                    // UTF-8 Decoded Tab
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: clr.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: clr.outlineVariant.withAlpha(50)),
                      ),
                      width: double.infinity,
                      child: Scrollbar(
                        thickness: 4,
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _getUtf8Text(msg.payload),
                            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: clr.onSurface),
                          ),
                        ),
                      ),
                    ),

                    // Base64 Tab
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: clr.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: clr.outlineVariant.withAlpha(50)),
                      ),
                      width: double.infinity,
                      child: Scrollbar(
                        thickness: 4,
                        child: SingleChildScrollView(
                          child: SelectableText(
                            base64Encode(pBytes),
                            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: clr.onSurface),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Payload: $payloadLength B    Total Packet: $totalPacketSize B",
                style: TextStyle(
                  color: clr.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class HexDumpViewer extends StatelessWidget {
  final Uint8List data;

  const HexDumpViewer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    
    // Build hex dump map lines
    final buffer = StringBuffer();
    for (int i = 0; i < data.length; i += 16) {
      // Memory Offset column
      buffer.write(i.toRadixString(16).padLeft(4, '0').toUpperCase());
      buffer.write('  ');
      
      // Hex representation column
      final end = (i + 16 < data.length) ? i + 16 : data.length;
      for (int j = i; j < i + 16; j++) {
        if (j < end) {
          buffer.write(data[j].toRadixString(16).padLeft(2, '0').toUpperCase());
          buffer.write(' ');
        } else {
          buffer.write('   ');
        }
        if (j == i + 7) buffer.write(' '); // Additional spacing at halfway mark
      }
      
      buffer.write('  ');
      
      // ASCII interpretation column
      for (int j = i; j < end; j++) {
        final byte = data[j];
        if (byte >= 32 && byte <= 126) {
          buffer.writeCharCode(byte);
        } else {
          buffer.write('.'); // Unprintable
        }
      }
      if (end < data.length) {
        buffer.writeln(); // Next line
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: clr.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: clr.outlineVariant.withAlpha(50)),
      ),
      child: Scrollbar(
        thickness: 4,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SelectableText(
              buffer.toString(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: clr.onSurface,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
