import re

def fix_file(filename, event_enum_prefix, is_grpc=False):
    with open(filename, 'r') as f:
        content = f.read()
    
    # 1. Fix the text fields
    content = re.sub(
        r'borderSide:\s*BorderSide\(\s*color:\s*Theme\.of\(context\)\.colorScheme\.outlineVariant,\s*\),',
        r'borderSide: const BorderSide(color: Colors.grey),',
        content
    )
    
    # Also add focusedBorder if missing
    if 'focusedBorder:' not in content:
        # Just replace enabledBorder with enabledBorder AND focusedBorder
        content = re.sub(
            r"(enabledBorder:\s*OutlineInputBorder\([\s\S]*?borderSide: const BorderSide\(color: Colors\.grey\),\s*\),)",
            r"\1\n                        focusedBorder: OutlineInputBorder(\n                          borderRadius: kBorderRadius8,\n                          borderSide: const BorderSide(color: Colors.grey),\n                        ),",
            content
        )

    # 2. Fix Event badges
    # First revert DataRow if we added color: WidgetStateProperty...
    content = re.sub(
        r'rows: events\.reversed\.map\(\(e\) {\s*return DataRow\(\s*color: WidgetStateProperty\.resolveWith<Color\?>\(\(states\) {[\s\S]*?}\),\s*cells: \[',
        r'rows: events.reversed.map((e) {\n        return DataRow(\n          cells: [',
        content
    )

    # Now update the badge container inside DataCell
    badge_pattern = r"DataCell\(\s*Container\(\s*padding: const EdgeInsets\.symmetric\([\s\S]*?\),\s*decoration: BoxDecoration\(\s*color: clr\.surfaceContainerHighest,\s*borderRadius: kBorderRadius4,\s*\),\s*child: Text\(\s*e\.type\.name\.toUpperCase\(\),\s*style: const TextStyle\(fontSize: 10\),\s*\),\s*\),\s*\),"
    
    green_condition = f"e.type == {event_enum_prefix}.connect"
    red_condition = f"(e.type == {event_enum_prefix}.error || e.type == {event_enum_prefix}.disconnect)"
    
    new_badge = f"""DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: {red_condition}
                      ? clr.errorContainer
                      : ({green_condition} ? Colors.green.withAlpha(50) : clr.surfaceContainerHighest),
                  borderRadius: kBorderRadius4,
                ),
                child: Text(
                  e.type.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: {red_condition}
                        ? clr.onErrorContainer
                        : ({green_condition} ? Colors.green : null),
                  ),
                ),
              ),
            ),"""
    
    content = re.sub(badge_pattern, new_badge, content)
    
    with open(filename, 'w') as f:
        f.write(content)

fix_file('lib/widgets/websocket/websocket_response_pane.dart', 'WebSocketEventType', is_grpc=False)
fix_file('lib/widgets/grpc_response_pane.dart', 'GrpcEventType', is_grpc=True)
