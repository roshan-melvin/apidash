import re

with open('lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Swap Config and Last Will in tabs
text = text.replace(
    "Tab(text: 'Config'),\n              Tab(text: 'Last Will'),",
    "Tab(text: 'Last Will'),\n              Tab(text: 'Config'),"
)

# Replace Publish Tab completely
regex_publish = r"                // ── Publish Tab ──────────────────────────────────────────.*?                // ── Config Tab ───────────────────────────────────────────"

new_publish = """                // ── Publish Tab ──────────────────────────────────────────
                Padding(
                  padding: kPh8v4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextFormField(
                          controller: _publishTopicCtrl,
                          decoration: fieldDeco.copyWith(
                            hintText: 'Topic (e.g. apidash/tele)',
                          ),
                          onChanged: (v) => _update((m) => m.copyWith(publishTopic: v)),
                        ),
                      ),
                      SizedBox(
                        height: kHeaderHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Select Content Type: '),
                            kHSpacer8,
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _publishContentType,
                                items: const [
                                  DropdownMenuItem(value: 'json', child: Text('json', style: kCodeStyle)),
                                  DropdownMenuItem(value: 'text', child: Text('text', style: kCodeStyle)),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _publishContentType = v;
                                    });
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: kPt5o10,
                          child: _publishContentType == 'json' ? JsonTextFieldEditor(
                            key: const Key("mqtt-json-body"),
                            fieldKey: "mqtt-json-body-editor",
                            isDark: Theme.of(context).brightness == Brightness.dark,
                            initialValue: model.publishPayload,
                            onChanged: (String value) => _update((m) => m.copyWith(publishPayload: value)),
                          ) : TextFieldEditor(
                            key: const Key("mqtt-text-body"),
                            fieldKey: "mqtt-text-body-editor",
                            initialValue: model.publishPayload,
                            onChanged: (String value) => _update((m) => m.copyWith(publishPayload: value)),
                          ),
                        ),
                      ),
                      kVSpacer8,
                      Row(
                        children: [
                          const Text('QoS: '),
                          kHSpacer8,
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('0')),
                              ButtonSegment(value: 1, label: Text('1')),
                              ButtonSegment(value: 2, label: Text('2')),
                            ],
                            selected: {model.publishQos},
                            onSelectionChanged: (Set<int> newSelection) =>
                                _update((m) => m.copyWith(publishQos: newSelection.first)),
                          ),
                          const Spacer(),
                          const Text('Retain: '),
                          Switch(
                            value: model.publishRetain,
                            onChanged: (v) => _update((m) => m.copyWith(publishRetain: v)),
                          ),
                          kHSpacer12,
                          FilledButton.icon(
                            onPressed: isConnected ? _publish : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: const RoundedRectangleBorder(borderRadius: kBorderRadius8),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Publish'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Config Tab ───────────────────────────────────────────"""

text = re.sub(regex_publish, new_publish, text, flags=re.DOTALL)

# Reorder Last Will and Config contents
regex_config = r"(                // ── Config Tab ───────────────────────────────────────────.*?)(                // ── Last Will Tab ─────────────────────────────────────────.*?)(              \],\n            \),\n          \),\n        \])"

import sys
match = re.search(regex_config, text, flags=re.DOTALL)
if match:
    config_body = match.group(1)
    last_will_body = match.group(2)
    end_tags = match.group(3)
    text = text[:match.start()] + last_will_body + config_body + end_tags + text[match.end():]
else:
    print("Could not find Config/Last Will to swap")
    sys.exit(1)


# Apply state and imports
if "import 'package:apidash/widgets/widgets.dart';" not in text:
    text = text.replace("import 'package:apidash/models/mqtt_request_model.dart';", "import 'package:apidash/models/mqtt_request_model.dart';\nimport 'package:apidash/widgets/widgets.dart';\nimport 'package:apidash_core/apidash_core.dart';")

if "String _publishContentType" not in text:
    text = text.replace("late final TextEditingController _publishPayloadCtrl;", 
                        "late final TextEditingController _publishPayloadCtrl;\n  String _publishContentType = 'json';")


with open('lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Modified mqtt_request_pane.dart successfully")
