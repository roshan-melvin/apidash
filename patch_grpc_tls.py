import sys

file_path = '/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/url_card.dart'

with open(file_path, 'r') as f:
    content = f.read()

# I will add a toggle button inside the URLTextField or next to the prefix.
# Looking at MQTT, it has a separate button or something. Let's just modify the GrpcRequestModel directly for this test.
