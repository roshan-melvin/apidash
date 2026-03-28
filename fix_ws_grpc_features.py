import re
import sys

# 1. FIX WS
path = 'lib/widgets/websocket/websocket_response_pane.dart'
with open(path, 'r') as f:
    text = f.read()

# Filter decoration fix for WS
ws_textfield_pattern = r"""TextField\(\s*onChanged: \(v\) => setState\(\(\) => _filterString = v\),\s*decoration: InputDecoration\(\s*prefixIcon: const Icon\(Icons.search, size: 16\),\s*hintText: 'Filter payload...',\s*isDense: true,\s*contentPadding: const EdgeInsets\.symmetric\([\s\S]*?\),\s*border: OutlineInputBorder\(\s*borderRadius: kBorderRadius8,\s*\),\s*\),\s*\),"""

ws_new_textfield = """TextField(
                            onChanged: (v) => setState(() => _filterString = v),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                              prefixIcon: const Icon(Icons.search, size: 16),
                              hintText: 'Filter payload...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: kBorderRadius8,
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: kBorderRadius8,
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                            ),
                          ),"""

text = re.sub(ws_textfield_pattern, ws_new_textfield, text)

# Event list color coding for WS
ws_event_color_regex = r"""DataCell\(\s*Container\(\s*padding: const EdgeInsets.symmetric\(horizontal: 6, vertical: 2\),\s*decoration: BoxDecoration\(\s*color: clr\.surfaceContainerHighest,\s*borderRadius: kBorderRadius4,\s*\),\s*child: Text\(\s*e\.type\.name\.toUpperCase\(\),\s*style: const TextStyle\(fontSize: 10\),\s*\),\s*\),\s*\)"""

ws_event_new_color = """DataCell(
                Builder(
                  builder: (context) {
                    final typeName = e.type.name.toLowerCase();
                    final isPositive = typeName.contains('connect') || typeName.contains('success');
                    final isNegative = typeName.contains('error') || typeName.contains('close') || typeName.contains('disconnect');
                    
                    Color bgColor = clr.surfaceContainerHighest;
                    Color textColor = clr.onSurface;
                    
                    if (isPositive) {
                      bgColor = clr.primaryContainer;
                      textColor = clr.onPrimaryContainer;
                    } else if (isNegative) {
                      bgColor = clr.errorContainer;
                      textColor = clr.onErrorContainer;
                    }
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: kBorderRadius4,
                      ),
                      child: Text(
                        e.type.name.toUpperCase(),
                        style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                ),
              )"""

text = re.sub(ws_event_color_regex, ws_event_new_color, text)

with open(path, 'w') as f:
    f.write(text)


# 2. FIX gRPC
path = 'lib/widgets/grpc_response_pane.dart'
with open(path, 'r') as f:
    text = f.read()

# Filter decoration fix for gRPC
grpc_textfield_pattern = r"""TextField\(\s*onChanged: \(v\) => setState\(\(\) => _filterString = v\),\s*decoration: InputDecoration\(\s*prefixIcon: const Icon\(Icons.search, size: 16\),\s*hintText: 'Filter payload...',\s*isDense: true,\s*contentPadding: const EdgeInsets\.symmetric\([\s\S]*?\),\s*border: OutlineInputBorder\(\s*borderRadius: kBorderRadius8,\s*\),\s*\),\s*\),"""

grpc_new_textfield = """TextField(
                            onChanged: (v) => setState(() => _filterString = v),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                              prefixIcon: const Icon(Icons.search, size: 16),
                              hintText: 'Filter payload...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: kBorderRadius8,
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: kBorderRadius8,
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                            ),
                          ),"""

text = re.sub(grpc_textfield_pattern, grpc_new_textfield, text)

# Event list color coding for gRPC
grpc_event_color_regex = r"""DataCell\(\s*Container\(\s*padding: const EdgeInsets.symmetric\(horizontal: 6, vertical: 2\),\s*decoration: BoxDecoration\(\s*color: clr\.surfaceContainerHighest,\s*borderRadius: kBorderRadius4,\s*\),\s*child: Text\(\s*e\.type\.name\.toUpperCase\(\),\s*style: const TextStyle\(fontSize: 10\),\s*\),\s*\),\s*\)"""

text = re.sub(grpc_event_color_regex, ws_event_new_color, text)

with open(path, 'w') as f:
    f.write(text)
