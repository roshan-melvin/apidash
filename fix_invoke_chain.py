import sys

content = open('lib/screens/home_page/editor_pane/url_card.dart', 'r').read()
content = content.replace("if (message != null && message.isNotEmpty) {", "if (message.isNotEmpty) {")

open('lib/screens/home_page/editor_pane/url_card.dart', 'w').write(content)
