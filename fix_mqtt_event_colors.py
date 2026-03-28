import re

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'r') as f:
    content = f.read()

# Replace the isPositive condition
new_condition = """
        // Red for errors, Green for positive
        final typeName = e.type.name.toLowerCase();
        final isError =
            typeName.contains('error') || typeName.contains('connectionfailed');
        final isPositive =
            typeName.contains('subscribe') ||
            typeName.contains('connect') ||
            typeName.contains('send') ||
            typeName.contains('receive');
"""

content = re.sub(
    r"        // Red for errors, Green for positive\s+final typeName = e\.type\.name\.toLowerCase\(\);\s+final isError =\n\s+typeName\.contains\('error'\) \|\| typeName\.contains\('connectionfailed'\);\s+final isPositive =\n\s+typeName\.contains\('subscribed'\) \|\|\n\s+typeName\.contains\('connected'\) \|\|\n\s+typeName\.contains\('published'\);",
    new_condition.strip(),
    content
)

with open('lib/widgets/mqtt/mqtt_response_pane.dart', 'w') as f:
    f.write(content)
