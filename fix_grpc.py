with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_metadata.dart', 'r') as f:
    text = f.read()

text = text.replace("rows.add(kNameValueEmptyModel);\n                  isRowEnabledList.add(false);//\n                      isRowEnabledList.length - 1, true);", 
"rows.add(kNameValueEmptyModel);\n                  isRowEnabledList.add(false);")

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/details_card/request_pane/grpc/grpc_metadata.dart', 'w') as f:
    f.write(text)
