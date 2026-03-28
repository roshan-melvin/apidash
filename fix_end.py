with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    text = f.read()

text = text.replace("          ],\n        ),\n      );\n    }\n  }",
                    "          ],\n        ),\n      ),\n    ));\n  }\n}")
with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(text)
