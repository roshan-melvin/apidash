import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:apidash/models/models.dart';

WebSocketChannel getChannel(Uri uri, WebSocketRequestModel request) {
  Map<String, dynamic>? headers;
  if (request.requestHeaders != null && request.requestHeaders!.isNotEmpty) {
    headers = {};
    for (var i = 0; i < request.requestHeaders!.length; i++) {
      final h = request.requestHeaders![i];
      // Check if it's enabled (or if the enabled list is shorter/missing, default to true)
      bool isEnabled = true;
      if (request.isHeaderEnabledList != null && i < request.isHeaderEnabledList!.length) {
        isEnabled = request.isHeaderEnabledList![i];
      }
      if (isEnabled && h.name.isNotEmpty) {
        headers[h.name] = h.value;
      }
    }
  }
  
  Duration? pingInterval;
  if (request.pingInterval > 0) {
    pingInterval = Duration(seconds: request.pingInterval);
  }

  return IOWebSocketChannel.connect(
    uri,
    headers: (headers != null && headers.isNotEmpty) ? headers : null,
    pingInterval: pingInterval,
  );
}
