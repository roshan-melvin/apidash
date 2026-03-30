import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/websocket_service.dart';

class WsFrameInspector extends StatefulWidget {
  final WebSocketMessage message;
  final String? connectionUrl;
  final Map<String, String>? connectionHeaders;
  final Map<String, String>? connectionParams;

  const WsFrameInspector({
    super.key,
    required this.message,
    this.connectionUrl,
    this.connectionHeaders,
    this.connectionParams,
  });

  @override
  State<WsFrameInspector> createState() => _WsFrameInspectorState();
}

class _WsFrameInspectorState extends State<WsFrameInspector> with SingleTickerProviderStateMixin {
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

  String _getUtf8Text(Uint8List bytes) {
    if (bytes.isEmpty) return "";
    try {
      final str = utf8.decode(bytes);
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
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: clr.onSurface,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
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
    final isOut = !msg.isIncoming;
    
    Uint8List pBytes;
    if (msg.payload is String) {
      pBytes = Uint8List.fromList(utf8.encode(msg.payload as String));
    } else if (msg.payload is List<int>) {
      pBytes = Uint8List.fromList(msg.payload as List<int>);
    } else {
      pBytes = Uint8List(0);
    }
    
    final payloadLength = pBytes.length;
    
    // Opcode detection
    final String opcodeStr;
    if (msg.isText) {
      opcodeStr = "0x1 (Text Frame)";
    } else {
      opcodeStr = "0x2 (Binary Frame)";
    }

    final bool isMasked = isOut;
    final maskingKeyStr = isMasked ? "00 00 00 00 (simulated)" : "N/A";
    final int maskingKeyBytes = isMasked ? 4 : 0;

    String lengthEncodingStr;
    int lengthBytes;
    if (payloadLength <= 125) {
      lengthEncodingStr = "7-bit";
      lengthBytes = 0; // base header includes 7-bit length portion
    } else if (payloadLength <= 65535) {
      lengthEncodingStr = "16-bit extended (0x7E)";
      lengthBytes = 2;
    } else {
      lengthEncodingStr = "64-bit extended (0x7F)";
      lengthBytes = 8;
    }
    
    final int baseHeaderBytes = 2;
    final int totalFrameSize = baseHeaderBytes + maskingKeyBytes + lengthBytes + payloadLength;
    final rmLengthHex = "0x${payloadLength.toRadixString(16).toUpperCase()}";

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
          // ── Handshake Context ──
          _HandshakeContextSection(
            connectionUrl: widget.connectionUrl,
            connectionHeaders: widget.connectionHeaders,
            connectionParams: widget.connectionParams,
          ),
          Divider(
            height: 16,
            thickness: 0.5,
            color: clr.outlineVariant.withAlpha(80),
          ),
          Text("Fixed Header", style: TextStyle(color: clr.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 24,
            children: [
              _buildPropertyRow("FIN", "true", clr),
              _buildPropertyRow("Opcode", opcodeStr, clr),
              _buildPropertyRow("Masked", isMasked.toString(), clr),
              _buildPropertyRow("RSV1/2/3", "false", clr),
            ],
          ),
          const SizedBox(height: 12),
          
          Text("Frame Length", style: TextStyle(color: clr.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 24,
            children: [
              _buildPropertyRow("Length Encoding", lengthEncodingStr, clr),
              _buildPropertyRow("Payload Length", "$payloadLength bytes ($rmLengthHex)", clr),
              _buildPropertyRow("Masking Key", maskingKeyStr, clr),
            ],
          ),
          const SizedBox(height: 16),

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
                    WsHexDumpViewer(data: pBytes),
                    
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
                            _getUtf8Text(pBytes),
                            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: clr.onSurface),
                          ),
                        ),
                      ),
                    ),

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
                "Payload: $payloadLength B    Total Frame: $totalFrameSize B",
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

// ── Handshake Context Section ──────────────────────────────────────────────

class _HandshakeContextSection extends StatelessWidget {
  final String? connectionUrl;
  final Map<String, String>? connectionHeaders;
  final Map<String, String>? connectionParams;

  const _HandshakeContextSection({
    this.connectionUrl,
    this.connectionHeaders,
    this.connectionParams,
  });

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;

    // Parse URL
    final rawUrl = connectionUrl ?? '';
    Uri? parsed;
    String baseUrl = 'N/A';
    Map<String, String> queryParams = {};

    if (rawUrl.isNotEmpty) {
      try {
        parsed = Uri.parse(rawUrl);
        // Base URL without query string or fragment
        baseUrl = parsed.replace(queryParameters: {}, fragment: null).toString();
        // Remove trailing '?' or '#' if any parser implementation keeps them
        if (baseUrl.endsWith('?') || baseUrl.endsWith('#')) {
          baseUrl = baseUrl.substring(0, baseUrl.length - 1);
        }
        
        queryParams = Map<String, String>.from(
          parsed.queryParameters,
        );
      } catch (_) {
        baseUrl = rawUrl;
      }
    }

    // Merge connection params
    if (connectionParams != null) {
      queryParams.addAll(connectionParams!);
    }

    final enabledHeaders = connectionHeaders ?? {};

    Widget buildLabel(String text) => SizedBox(
          width: 100,
          child: Text(
            text,
            style: TextStyle(
              color: clr.outline,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

    Widget buildValue(String text) => Expanded(
          child: SelectableText(
            text,
            style: TextStyle(
              color: clr.onSurface,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        );

    // Build query param rows
    Widget queryParamsWidget;
    if (queryParams.isEmpty) {
      queryParamsWidget = Row(
        children: [
          buildLabel('Query Params:'),
          buildValue('(none)'),
        ],
      );
    } else {
      final entries = queryParams.entries.toList();
      queryParamsWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  buildLabel(i == 0 ? 'Query Params:' : ''),
                  buildValue('${entries[i].key} = ${entries[i].value}'),
                ],
              ),
            ),
        ],
      );
    }

    // Build header rows
    Widget headersWidget;
    if (enabledHeaders.isEmpty) {
      headersWidget = Row(
        children: [
          buildLabel('Headers:'),
          buildValue('(none)'),
        ],
      );
    } else {
      final entries = enabledHeaders.entries.toList();
      headersWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  buildLabel(i == 0 ? 'Headers:' : ''),
                  buildValue('${entries[i].key} = ${entries[i].value}'),
                ],
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Handshake Context',
          style: TextStyle(
            color: clr.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            buildLabel('Upgrade URL:'),
            buildValue(baseUrl),
          ],
        ),
        const SizedBox(height: 2),
        queryParamsWidget,
        const SizedBox(height: 2),
        headersWidget,
        const SizedBox(height: 2),
        Row(
          children: [
            buildLabel('Protocol:'),
            buildValue('WebSocket/HTTP 1.1'),
          ],
        ),
      ],
    );
  }
}

class WsHexDumpViewer extends StatelessWidget {
  final Uint8List data;

  const WsHexDumpViewer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    
    final buffer = StringBuffer();
    for (int i = 0; i < data.length; i += 16) {
      buffer.write(i.toRadixString(16).padLeft(4, '0').toUpperCase());
      buffer.write('  ');
      
      final end = (i + 16 < data.length) ? i + 16 : data.length;
      for (int j = i; j < i + 16; j++) {
        if (j < end) {
          buffer.write(data[j].toRadixString(16).padLeft(2, '0').toUpperCase());
          buffer.write(' ');
        } else {
          buffer.write('   ');
        }
        if (j == i + 7) buffer.write(' ');
      }
      
      buffer.write('  ');
      
      for (int j = i; j < end; j++) {
        final byte = data[j];
        if (byte >= 32 && byte <= 126) {
          buffer.writeCharCode(byte);
        } else {
          buffer.write('.');
        }
      }
      if (end < data.length) {
        buffer.writeln();
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
