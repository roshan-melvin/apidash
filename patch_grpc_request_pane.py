import re

with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_request_pane.dart', 'r') as f:
    content = f.read()

# Replace Service Def with Server Ref
content = content.replace('Tab(text: "Service Def")', 'Tab(text: "Server Ref")')

# Remove the bottom Row with Service and Method textfields
pattern = r'(\s*kVSpacer10,\s*Padding\(\s*padding: kPh20,\s*child: Row\(\s*children: \[\s*Expanded\(\s*child: TextFormField\([\s\S]*?kVSpacer10,)'
match = re.search(pattern, content)
if match:
    content = content.replace(match.group(1), "")
else:
    print("Could not find bottom row")
    
with open('lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_request_pane.dart', 'w') as f:
    f.write(content)
