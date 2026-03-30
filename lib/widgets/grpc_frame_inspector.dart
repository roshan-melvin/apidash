import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';

class GrpcFrameInspector extends StatefulWidget {
  final Uint8List payloadBytes;
  final bool isOutgoing;
  final String serverUrl;
  final String serviceName;
  final String methodName;

  const GrpcFrameInspector({
    super.key,
    required this.payloadBytes,
    required this.isOutgoing,
    required this.serverUrl,
    required this.serviceName,
    required this.methodName,
  });

  @override
  State<GrpcFrameInspector> createState() => _GrpcFrameInspectorState();
}

class _GrpcFrameInspectorState extends State<GrpcFrameInspector>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConnectionContextSection(
          serverUrl: widget.serverUrl,
          serviceName: widget.serviceName,
          methodName: widget.methodName,
        ),
        const Divider(height: 24),
        _FrameHeaderSection(payloadLength: widget.payloadBytes.length),
        const Divider(height: 24),
        _Http2ContextSection(
          isOutgoing: widget.isOutgoing,
          serverUrl: widget.serverUrl,
          serviceName: widget.serviceName,
          methodName: widget.methodName,
        ),
        const Divider(height: 24),
        _PayloadSection(
          payloadBytes: widget.payloadBytes,
          tabController: _tabController,
        ),
      ],
    );
  }
}

class _ConnectionContextSection extends StatelessWidget {
  final String serverUrl;
  final String serviceName;
  final String methodName;

  const _ConnectionContextSection({
    required this.serverUrl,
    required this.serviceName,
    required this.methodName,
  });

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final scheme = serverUrl.startsWith('https') || serverUrl.contains(':443')
        ? 'https'
        : 'http';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connection Context',
          style: TextStyle(
            color: clr.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _PropertyRow(label: 'Server:', value: serverUrl.isNotEmpty ? serverUrl : 'N/A'),
        _PropertyRow(label: 'Scheme:', value: scheme),
        _PropertyRow(label: 'Service:', value: serviceName.isNotEmpty ? serviceName : 'N/A'),
        _PropertyRow(label: 'Method:', value: methodName.isNotEmpty ? methodName : 'N/A'),
        _PropertyRow(label: 'HTTP/2 Method:', value: 'POST'),
        _PropertyRow(label: 'Content-Type:', value: 'application/grpc+proto'),
      ],
    );
  }
}

class _FrameHeaderSection extends StatelessWidget {
  final int payloadLength;

  const _FrameHeaderSection({required this.payloadLength});

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final hexLen = payloadLength.toRadixString(16).padLeft(8, '0').toUpperCase();
    final totalSize = 5 + payloadLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'gRPC Frame Header',
          style: TextStyle(
            color: clr.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _PropertyRow(label: 'Compression Flag:', value: '0x00 (Not Compressed)'),
        _PropertyRow(
          label: 'Message Length:',
          value: '$payloadLength bytes (0x$hexLen)',
        ),
        _PropertyRow(
          label: 'Header Bytes:',
          value: '[ 00 ${hexLen.substring(0, 2)} ${hexLen.substring(2, 4)} ${hexLen.substring(4, 6)} ${hexLen.substring(6, 8)} ]',
        ),
        _PropertyRow(label: 'Total Frame Size:', value: '$totalSize bytes (5-byte header + $payloadLength-byte payload)'),
      ],
    );
  }
}

class _Http2ContextSection extends StatelessWidget {
  final bool isOutgoing;
  final String serverUrl;
  final String serviceName;
  final String methodName;

  const _Http2ContextSection({
    required this.isOutgoing,
    required this.serverUrl,
    required this.serviceName,
    required this.methodName,
  });

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final scheme = serverUrl.startsWith('https') || serverUrl.contains(':443')
        ? 'https'
        : 'http';
    final path = '/$serviceName/$methodName';
    final status = isOutgoing ? 'N/A (request)' : '0 (OK)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HTTP/2 Context',
          style: TextStyle(
            color: clr.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _PropertyRow(label: ':method:', value: 'POST'),
        _PropertyRow(label: ':scheme:', value: scheme),
        _PropertyRow(label: ':path:', value: path),
        _PropertyRow(label: ':authority:', value: serverUrl.isNotEmpty ? serverUrl : 'N/A'),
        _PropertyRow(label: 'content-type:', value: 'application/grpc+proto'),
        _PropertyRow(label: 'grpc-status:', value: status),
      ],
    );
  }
}

class _PayloadSection extends StatelessWidget {
  final Uint8List payloadBytes;
  final TabController tabController;

  const _PayloadSection({
    required this.payloadBytes,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final payloadStr = utf8.decode(payloadBytes, allowMalformed: true);
    
    String detectedFormat = 'Binary / Protobuf';
    try {
      jsonDecode(payloadStr);
      detectedFormat = 'JSON';
    } catch (_) {
      try {
        utf8.decode(payloadBytes);
        detectedFormat = 'UTF-8 Text';
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Detected Format: $detectedFormat',
              style: TextStyle(
                color: clr.outline,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: tabController,
          dividerColor: Colors.transparent,
          labelColor: clr.primary,
          unselectedLabelColor: clr.outline,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'HEX'),
            Tab(text: 'UTF-8'),
            Tab(text: 'Base64'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: TabBarView(
            controller: tabController,
            children: [
              _LocalHexDumpViewer(data: payloadBytes),
              _Utf8Viewer(payloadBytes: payloadBytes),
              _Base64Viewer(payloadBytes: payloadBytes),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Payload: ${payloadBytes.length} B    Total Frame: ${5 + payloadBytes.length} B',
              style: TextStyle(
                color: clr.outline,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Utf8Viewer extends StatelessWidget {
  final Uint8List payloadBytes;

  const _Utf8Viewer({required this.payloadBytes});

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    String content = utf8.decode(payloadBytes, allowMalformed: true);
    
    try {
      final decoded = jsonDecode(content);
      content = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {}

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
          child: SelectableText(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: clr.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _Base64Viewer extends StatelessWidget {
  final Uint8List payloadBytes;

  const _Base64Viewer({required this.payloadBytes});

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final content = base64.encode(payloadBytes);

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
          child: SelectableText(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: clr.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final String label;
  final String value;

  const _PropertyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: clr.outline,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
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
}

class _LocalHexDumpViewer extends StatelessWidget {
  final Uint8List data;

  const _LocalHexDumpViewer({required this.data});

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
