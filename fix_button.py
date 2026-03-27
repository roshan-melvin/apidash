import re

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/url_card.dart', 'r') as f:
    text = f.read()

text = text.replace('_isInvoking ? null : _invoke', 'isConnected || isConnecting ? null : _invoke')
text = text.replace('icon: _isInvoking', 'icon: isConnecting')
text = text.replace("_isInvoking ? 'Invoking...' : 'Invoke'", "isConnecting ? 'Invoking...' : 'Invoke'")

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/url_card.dart', 'w') as f:
    f.write(text)
