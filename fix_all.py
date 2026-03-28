import re
import os

files = {
    'websocket': 'lib/widgets/websocket/websocket_response_pane.dart',
    'grpc': 'lib/widgets/grpc_response_pane.dart',
    'mqtt': 'lib/widgets/mqtt/mqtt_response_pane.dart'
}

for key, path in files.items():
    with open(path, 'r') as f:
        text = f.read()

    if key == 'mqtt':
        # MQTT uses Expanded(child: TextFormField(controller: _topicFilterCtrl...))
        # We need to replace it with Expanded(child: SearchField(controller: _topicFilterCtrl, onChanged: ..., hintText: 'Filter by topic...'))
        pattern_mqtt_search = r"""Expanded\(\s*child:\s*TextFormField\(\s*controller:\s*_topicFilterCtrl,\s*onChanged:\s*\(v\)\s*=>\s*setState\(\(\)\s*=>\s*_filterTopic\s*=\s*v\),\s*decoration:\s*InputDecoration\([\s\S]*?suffixIcon:[\s\S]*?\)\s*:\s*null,\s*\),\s*\),\s*\),"""
        replacement_mqtt_search = r"""Expanded(
                    child: SearchField(
                      controller: _topicFilterCtrl,
                      onChanged: (v) => setState(() => _filterTopic = v),
                      hintText: 'Filter by topic...',
                    ),
                  ),"""
        text = re.sub(pattern_mqtt_search, replacement_mqtt_search, text)
        
        # Remove Event tab filter
        # It's inside IndexedStack children list. Let's find the exact padding.
        # kPh8v4 padding with _eventFilterCtrl
        pattern_event = r"""Padding\(\s*padding:\s*kPh8v4,\s*child:\s*TextFormField\(\s*controller:\s*_eventFilterCtrl,[\s\S]*?suffixIcon:[\s\S]*?\)\s*:\s*null,\s*\),\s*\),\s*\),"""
        text = re.sub(pattern_event, "kSizedBoxEmpty,", text)

        # Import SearchField if missing
        if "import 'package:apidash/widgets/field_search.dart';" not in text and "import '../field_search.dart';" not in text:
            # Add to top
            text = text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:apidash/widgets/widgets.dart';")
            
    elif key in ('websocket', 'grpc'):
        pattern_ws_search = r"""Expanded\(\s*child:\s*TextField\(\s*onChanged:\s*\(v\)\s*=>\s*setState\(\(\)\s*=>\s*_filterString\s*=\s*v\),[\s\S]*?borderRadius:\s*kBorderRadius8,\s*\),\s*\),\s*\),\s*\),"""
        replacement_ws_search = r"""Expanded(
                        child: SearchField(
                          onChanged: (v) => setState(() => _filterString = v),
                          hintText: 'Filter payload...',
                        ),
                      ),"""
        text = re.sub(pattern_ws_search, replacement_ws_search, text)

        # Let's also check if they used TextFormField for some reason?
        pattern_ws_form = r"""Expanded\(\s*child:\s*TextFormField\(\s*onChanged:\s*\(v\)\s*=>\s*setState\(\(\)\s*=>\s*_filterString\s*=\s*v\),[\s\S]*?borderRadius:\s*kBorderRadius8,\s*\),\s*\),\s*\),\s*\),"""
        text = re.sub(pattern_ws_form, replacement_ws_search, text)
        
        # Now remove event filter
        pattern_event = r"""Padding\(\s*padding:\s*kPh8v4,\s*child:\s*TextFormField\(\s*controller:\s*_eventFilterCtrl,[\s\S]*?suffixIcon:[\s\S]*?\)\s*:\s*null,\s*\),\s*\),\s*\)"""
        text = re.sub(pattern_event, "kSizedBoxEmpty", text)
        
        if "import 'package:apidash/widgets/field_search.dart';" not in text and "import '../field_search.dart';" not in text:
            text = text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:apidash/widgets/widgets.dart';")

    with open(path, 'w') as f:
        f.write(text)

print("Done")

