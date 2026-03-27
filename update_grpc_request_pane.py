import re

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_request_pane.dart', 'r') as f:
    content = f.read()

content = content.replace('''          onTap: (index) {
          },''', '''          onTap: (index) {
            ref
                .read(collectionStateNotifierProvider.notifier)
                .updateGrpcModel(requestTabIndex: index);
          },''')

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_request_pane.dart', 'w') as f:
    f.write(content)

