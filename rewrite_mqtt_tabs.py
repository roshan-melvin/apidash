import re

with open('lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Imports and state
if "import 'package:apidash/widgets/widgets.dart';" not in text:
    text = text.replace("import 'package:apidash/models/mqtt_request_model.dart';", "import 'package:apidash/models/mqtt_request_model.dart';\nimport 'package:apidash/widgets/widgets.dart';\nimport 'package:apidash_core/apidash_core.dart';")

if "String _publishContentType" not in text:
    text = text.replace("late final TextEditingController _publishPayloadCtrl;", 
                        "late final TextEditingController _publishPayloadCtrl;\n  String _publishContentType = 'json';")


# 2. Fix the Tabs order array
tabs_pattern = r"(const TabBar\(\s*tabs: \[\s*Tab\(text: 'Topics'\),\s*Tab\(text: 'Publish'\),\s*)Tab\(text: 'Config'\),\s*Tab\(text: 'Last Will'\),"

text = re.sub(tabs_pattern, r"\1Tab(text: 'Last Will'),\n              Tab(text: 'Config'),", text)

# 3. Extract the tab bodies
publish_tab_re = re.search(r"// ── Publish Tab ──.*?                // ── Config Tab ──", text, re.DOTALL)
config_tab_re = re.search(r"// ── Config Tab ──.*?                // ── Last Will Tab ──", text, re.DOTALL)
last_will_tab_re = re.search(r"// ── Last Will Tab ──.*?              \],\s*\),\s*\),\s*\]", text, re.DOTALL)

if not publish_tab_re or not config_tab_re or not last_will_tab_re:
    print("Failed to find tab segments!")

publish_tab_content = publish_tab_re.group(0).replace("                // ── Config Tab ──", "").strip()
config_tab_content = config_tab_re.group(0).replace("                // ── Last Will Tab ──", "").strip()
last_will_tab_content = last_will_tab_re.group(0).replace("              ],\n            ),\n          ),\n        ]", "").strip()

# Now rebuild the inner part of TabBarView
# I am rewriting publish_tab_content heavily based on the user's instructions:
# Center the content type dropdown.

publish_tab_content = """// ── Publish Tab ──────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: kHeaderHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Select Content Type: '),
                          // ADDropdownButton<String>(
                          //  value: _publishContentType,
                          //  values: const [('json', 'json'), ('text', 'text')],
                          //  onChanged: (v) { if (v!=null) setState(() => _publishContentType = v); },
                          // )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: kPt5o10,
                        child: _publishContentType == 'json' ? JsonTextFieldEditor(
                          key: Key("mqtt-json-body"),
                          fieldKey: "mqtt-json-body-editor",
                          isDark: Theme.of(context).brightness == Brightness.dark,
                          initialValue: model.publishPayload,
                          onChanged: (String value) => _update((m) => m.copyWith(publishPayload: value)),
                        ) : TextFieldEditor(
                          key: Key("mqtt-text-body"),
                          fieldKey: "mqtt-text-body-editor",
                          initialValue: model.publishPayload,
                          onChanged: (String value) => _update((m) => m.copyWith(publishPayload: value)),
                        ),
                      ),
                    ),
                  ]
                )"""


publish_tab_full = """// ── Publish Tab ──────────────────────────────────────────
                Padding(
                  padding: kPh8v4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: kHeaderHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(kLabelSelectContentType),
                            kHSpacer8,
                            // Ideally ADDropdownButton, but let's use standard Dropdown
                          ],
                        ),
                      ),
                      // We will refine this later. Let's finish the skeleton first.
"""
