import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:apidash/models/models.dart';

WebSocketChannel getChannel(Uri uri, WebSocketRequestModel request) {
  throw UnsupportedError('Cannot create a WebSocket channel on this platform');
}
