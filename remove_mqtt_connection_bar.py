import re

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'r') as f:
    text = f.read()

# Replace the connection bar Card and the error text
start_idx = text.find('// ── Connection bar')
# Find the next section: Tabs
end_idx = text.find('// ── Tabs', start_idx)

if start_idx != -1 and end_idx != -1:
    text = text[:start_idx] + text[end_idx:]

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/mqtt/mqtt_request_pane.dart', 'w') as f:
    f.write(text)

