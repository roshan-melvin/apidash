import sys

file_path = '/home/rocroshan/Desktop/GSOC/apidash/lib/services/websocket_service.dart'

with open(file_path, 'r') as f:
    content = f.read()

content = content.replace(
"""import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/websocket_request_model.dart';""",
"""import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/websocket_request_model.dart';
import 'get_channel.dart';""")

content = content.replace(
"""      // web_socket_channel handles both VM and web platforms seamlessly
      _channel = WebSocketChannel.connect(uri);""",
"""      // Use factory to support headers on IO and gracefully degrade on Web
      _channel = getChannel(uri, request);""")

with open(file_path, 'w') as f:
    f.write(content)
