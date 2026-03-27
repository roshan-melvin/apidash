import re

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/editor_request.dart', 'r') as f:
    text = f.read()

text = text.replace("if (apiType != APIType.mqtt) const EditorPaneRequestURLCard(),", "const EditorPaneRequestURLCard(),")
text = text.replace("if (apiType != APIType.mqtt) kVSpacer10,", "kVSpacer10,")

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/editor_request.dart', 'w') as f:
    f.write(text)

