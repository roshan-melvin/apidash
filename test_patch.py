import re

with open('lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# ADD IMPORTS
if "import 'package:apidash/widgets/widgets.dart';" not in text:
    text = text.replace("import 'package:apidash/models/mqtt_request_model.dart';", "import 'package:apidash/models/mqtt_request_model.dart';\nimport 'package:apidash/widgets/widgets.dart';\nimport 'package:apidash_core/apidash_core.dart';")

# ADD STATE PROPERTY
if "String _publishContentType = 'json';" not in text:
    text = text.replace("late final TextEditingController _publishPayloadCtrl;", "late final TextEditingController _publishPayloadCtrl;\n  String _publishContentType = 'json';")

with open('mqtt_request_pane_patched_2.dart', 'w', encoding='utf-8') as f:
    f.write(text)

