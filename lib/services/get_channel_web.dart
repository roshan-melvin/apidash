import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:apidash/models/models.dart';

WebSocketChannel getChannel(Uri uri, WebSocketRequestModel request) {
  // Web doesn't support custom headers, but we can pass protocols if needed
  return HtmlWebSocketChannel.connect(uri);
}
