import 'package:apidash/models/websocket_request_model.dart';
// For NameValueModel

class WebSocketCCodeGen {
  String getCode(WebSocketRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;

    buf.writeln('#include <libwebsockets.h>');
    buf.writeln('#include <string.h>');
    buf.writeln('#include <stdio.h>');
    buf.writeln();
    buf.writeln(
      'static int callback_ws(struct lws *wsi, enum lws_callback_reasons reason,',
    );
    buf.writeln('                       void *user, void *in, size_t len) {');
    buf.writeln('    switch (reason) {');
    buf.writeln('        case LWS_CALLBACK_CLIENT_ESTABLISHED:');
    buf.writeln('            printf("Connected!\\n");');
    buf.writeln('            lws_callback_on_writable(wsi);');
    buf.writeln('            break;');
    buf.writeln('        case LWS_CALLBACK_CLIENT_RECEIVE:');
    buf.writeln(
      '            printf("Received: %.*s\\n", (int)len, (char *)in);',
    );
    buf.writeln('            break;');
    buf.writeln('        case LWS_CALLBACK_CLIENT_WRITEABLE: {');
    buf.writeln('            const char *msg = "Hello from APIDash";');
    buf.writeln('            unsigned char buf[LWS_PRE + 128];');
    buf.writeln('            memcpy(&buf[LWS_PRE], msg, strlen(msg));');
    buf.writeln(
      '            lws_write(wsi, &buf[LWS_PRE], strlen(msg), LWS_WRITE_TEXT);',
    );
    buf.writeln('            break;');
    buf.writeln('        }');
    buf.writeln('        default: break;');
    buf.writeln('    }');
    buf.writeln('    return 0;');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('// Connect to: $url');
    return buf.toString();
  }
}

class WebSocketCSharpCodeGen {
  String getCode(WebSocketRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;

    final headers = (model.requestHeaders ?? [])
        .asMap()
        .entries
        .where(
          (e) =>
              model.isHeaderEnabledList == null ||
              (model.isHeaderEnabledList!.length > e.key &&
                  model.isHeaderEnabledList![e.key]),
        )
        .map((e) => e.value)
        .where((h) => h.name.isNotEmpty)
        .toList();

    buf.writeln('using System;');
    buf.writeln('using System.Net.WebSockets;');
    buf.writeln('using System.Text;');
    buf.writeln('using System.Threading;');
    buf.writeln('using System.Threading.Tasks;');
    buf.writeln();
    buf.writeln('class Program {');
    buf.writeln('    static async Task Main() {');
    buf.writeln('        using var ws = new ClientWebSocket();');
    buf.writeln();
    if (headers.isNotEmpty) {
      for (final h in headers) {
        buf.writeln(
          '        ws.Options.SetRequestHeader("${h.name}", "${h.value}");',
        );
      }
      buf.writeln();
    }
    buf.writeln(
      '        await ws.ConnectAsync(new Uri("$url"), CancellationToken.None);',
    );
    buf.writeln('        Console.WriteLine("Connected!");');
    buf.writeln();
    buf.writeln('        // Send a message');
    buf.writeln(
      '        var msg = Encoding.UTF8.GetBytes("Hello from APIDash");',
    );
    buf.writeln(
      '        await ws.SendAsync(msg, WebSocketMessageType.Text, true, CancellationToken.None);',
    );
    buf.writeln();
    buf.writeln('        // Receive messages');
    buf.writeln('        var buffer = new byte[4096];');
    buf.writeln('        while (ws.State == WebSocketState.Open) {');
    buf.writeln(
      '            var result = await ws.ReceiveAsync(buffer, CancellationToken.None);',
    );
    buf.writeln(
      '            Console.WriteLine(Encoding.UTF8.GetString(buffer, 0, result.Count));',
    );
    buf.writeln('        }');
    buf.writeln('    }');
    buf.writeln('}');
    return buf.toString();
  }
}

class WebSocketGoCodeGen {
  String getCode(WebSocketRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;

    final headers = (model.requestHeaders ?? [])
        .asMap()
        .entries
        .where(
          (e) =>
              model.isHeaderEnabledList == null ||
              (model.isHeaderEnabledList!.length > e.key &&
                  model.isHeaderEnabledList![e.key]),
        )
        .map((e) => e.value)
        .where((h) => h.name.isNotEmpty)
        .toList();

    buf.writeln('package main');
    buf.writeln();
    buf.writeln('import (');
    buf.writeln('\t"fmt"');
    buf.writeln('\t"log"');
    buf.writeln('\t"github.com/gorilla/websocket"');
    if (headers.isNotEmpty) {
      buf.writeln('\t"net/http"');
    }
    buf.writeln(')');
    buf.writeln();
    buf.writeln('func main() {');
    if (headers.isNotEmpty) {
      buf.writeln('\theader := http.Header{}');
      for (final h in headers) {
        buf.writeln('\theader.Add("${h.name}", "${h.value}")');
      }
      buf.writeln(
        '\tc, _, err := websocket.DefaultDialer.Dial("$url", header)',
      );
    } else {
      buf.writeln('\tc, _, err := websocket.DefaultDialer.Dial("$url", nil)');
    }
    buf.writeln('\tif err != nil { log.Fatal("Dial error:", err) }');
    buf.writeln('\tdefer c.Close()');
    buf.writeln('\tfmt.Println("Connected!")');
    buf.writeln();
    buf.writeln('\t// Send a message');
    buf.writeln(
      '\terr = c.WriteMessage(websocket.TextMessage, []byte("Hello from APIDash"))',
    );
    buf.writeln('\tif err != nil { log.Println("Write error:", err); return }');
    buf.writeln();
    buf.writeln('\t// Read messages');
    buf.writeln('\tfor {');
    buf.writeln('\t\t_, message, err := c.ReadMessage()');
    buf.writeln(
      '\t\tif err != nil { log.Println("Read error:", err); return }',
    );
    buf.writeln('\t\tfmt.Printf("Received: %s\\n", message)');
    buf.writeln('\t}');
    buf.writeln('}');
    return buf.toString();
  }
}

class WebSocketJavaCodeGen {
  String getCode(WebSocketRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;

    final headers = (model.requestHeaders ?? [])
        .asMap()
        .entries
        .where(
          (e) =>
              model.isHeaderEnabledList == null ||
              (model.isHeaderEnabledList!.length > e.key &&
                  model.isHeaderEnabledList![e.key]),
        )
        .map((e) => e.value)
        .where((h) => h.name.isNotEmpty)
        .toList();

    buf.writeln('import org.java_websocket.client.WebSocketClient;');
    buf.writeln('import org.java_websocket.handshake.ServerHandshake;');
    buf.writeln('import java.net.URI;');
    if (headers.isNotEmpty) {
      buf.writeln('import java.util.Map;');
      buf.writeln('import java.util.HashMap;');
    }
    buf.writeln();
    buf.writeln('public class WSClient extends WebSocketClient {');
    if (headers.isNotEmpty) {
      buf.writeln(
        '    public WSClient(URI uri, Map<String, String> httpHeaders) {',
      );
      buf.writeln(
        '        super(uri, new org.java_websocket.drafts.Draft_64(), httpHeaders, 0);',
      );
      buf.writeln('    }');
    } else {
      buf.writeln('    public WSClient(URI uri) { super(uri); }');
    }
    buf.writeln();
    buf.writeln(
      '    @Override public void onOpen(ServerHandshake handshake) {',
    );
    buf.writeln('        System.out.println("Connected!");');
    buf.writeln('        send("Hello from APIDash");');
    buf.writeln('    }');
    buf.writeln('    @Override public void onMessage(String message) {');
    buf.writeln('        System.out.println("Received: " + message);');
    buf.writeln('    }');
    buf.writeln(
      '    @Override public void onClose(int code, String reason, boolean remote) {',
    );
    buf.writeln('        System.out.println("Closed: " + reason);');
    buf.writeln('    }');
    buf.writeln(
      '    @Override public void onError(Exception ex) { ex.printStackTrace(); }',
    );
    buf.writeln();
    buf.writeln(
      '    public static void main(String[] args) throws Exception {',
    );
    if (headers.isNotEmpty) {
      buf.writeln('        Map<String, String> headers = new HashMap<>();');
      for (final h in headers) {
        buf.writeln('        headers.put("${h.name}", "${h.value}");');
      }
      buf.writeln('        new WSClient(new URI("$url"), headers).connect();');
    } else {
      buf.writeln('        new WSClient(new URI("$url")).connect();');
    }
    buf.writeln('    }');
    buf.writeln('}');
    return buf.toString();
  }
}

class WebSocketKotlinCodeGen {
  String getCode(WebSocketRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;

    final headers = (model.requestHeaders ?? [])
        .asMap()
        .entries
        .where(
          (e) =>
              model.isHeaderEnabledList == null ||
              (model.isHeaderEnabledList!.length > e.key &&
                  model.isHeaderEnabledList![e.key]),
        )
        .map((e) => e.value)
        .where((h) => h.name.isNotEmpty)
        .toList();

    buf.writeln('import okhttp3.*');
    buf.writeln();
    buf.writeln('fun main() {');
    buf.writeln('    val client = OkHttpClient()');
    buf.writeln('    val requestBuilder = Request.Builder().url("$url")');
    if (headers.isNotEmpty) {
      for (final h in headers) {
        buf.writeln('        .addHeader("${h.name}", "${h.value}")');
      }
    }
    buf.writeln('    val request = requestBuilder.build()');
    buf.writeln();
    buf.writeln('    val listener = object : WebSocketListener() {');
    buf.writeln(
      '        override fun onOpen(ws: WebSocket, response: Response) {',
    );
    buf.writeln('            println("Connected!")');
    buf.writeln('            ws.send("Hello from APIDash")');
    buf.writeln('        }');
    buf.writeln(
      '        override fun onMessage(ws: WebSocket, text: String) {',
    );
    buf.writeln('            println("Received: \$text")');
    buf.writeln('        }');
    buf.writeln(
      '        override fun onFailure(ws: WebSocket, t: Throwable, response: Response?) {',
    );
    buf.writeln('            t.printStackTrace()');
    buf.writeln('        }');
    buf.writeln('    }');
    buf.writeln();
    buf.writeln('    client.newWebSocket(request, listener)');
    buf.writeln('    client.dispatcher.executorService.shutdown()');
    buf.writeln('}');
    return buf.toString();
  }
}

class WebSocketPHPCodeGen {
  String getCode(WebSocketRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;

    final headers = (model.requestHeaders ?? [])
        .asMap()
        .entries
        .where(
          (e) =>
              model.isHeaderEnabledList == null ||
              (model.isHeaderEnabledList!.length > e.key &&
                  model.isHeaderEnabledList![e.key]),
        )
        .map((e) => e.value)
        .where((h) => h.name.isNotEmpty)
        .toList();

    buf.writeln('<?php');
    buf.writeln('require "vendor/autoload.php";');
    buf.writeln();
    buf.writeln('use WebSocket\\Client;');
    buf.writeln();
    if (headers.isNotEmpty) {
      buf.writeln('\$headers = [');
      for (final h in headers) {
        buf.writeln('    "${h.name}" => "${h.value}",');
      }
      buf.writeln('];');
      buf.writeln('\$client = new Client("$url", ["headers" => \$headers]);');
    } else {
      buf.writeln('\$client = new Client("$url");');
    }
    buf.writeln('\$client->send("Hello from APIDash");');
    buf.writeln();
    buf.writeln('while (true) {');
    buf.writeln('    \$message = \$client->receive();');
    buf.writeln('    echo "Received: " . \$message . "\\n";');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('\$client->close();');
    return buf.toString();
  }
}

class WebSocketRubyCodeGen {
  String getCode(WebSocketRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;

    final headers = (model.requestHeaders ?? [])
        .asMap()
        .entries
        .where(
          (e) =>
              model.isHeaderEnabledList == null ||
              (model.isHeaderEnabledList!.length > e.key &&
                  model.isHeaderEnabledList![e.key]),
        )
        .map((e) => e.value)
        .where((h) => h.name.isNotEmpty)
        .toList();

    buf.writeln('require "websocket-client-simple"');
    buf.writeln();
    if (headers.isNotEmpty) {
      buf.writeln('headers = {');
      for (final h in headers) {
        buf.writeln('  "${h.name}" => "${h.value}",');
      }
      buf.writeln('}');
      buf.writeln(
        'ws = WebSocket::Client::Simple.connect "$url", headers: headers',
      );
    } else {
      buf.writeln('ws = WebSocket::Client::Simple.connect "$url"');
    }
    buf.writeln();
    buf.writeln('ws.on :open do');
    buf.writeln('  puts "Connected!"');
    buf.writeln('  ws.send "Hello from APIDash"');
    buf.writeln('end');
    buf.writeln();
    buf.writeln('ws.on :message do |msg|');
    buf.writeln('  puts "Received: #{msg.data}"');
    buf.writeln('end');
    buf.writeln();
    buf.writeln('ws.on :error do |e|');
    buf.writeln('  puts "Error: #{e.message}"');
    buf.writeln('end');
    buf.writeln();
    buf.writeln('loop { sleep 1 }');
    return buf.toString();
  }
}

class WebSocketRustCodeGen {
  String getCode(WebSocketRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;

    final headers = (model.requestHeaders ?? [])
        .asMap()
        .entries
        .where(
          (e) =>
              model.isHeaderEnabledList == null ||
              (model.isHeaderEnabledList!.length > e.key &&
                  model.isHeaderEnabledList![e.key]),
        )
        .map((e) => e.value)
        .where((h) => h.name.isNotEmpty)
        .toList();

    buf.writeln(
      'use tokio_tungstenite::{connect_async, tungstenite::Message};',
    );
    buf.writeln('use futures_util::{SinkExt, StreamExt};');
    buf.writeln('use url::Url;');
    if (headers.isNotEmpty) {
      buf.writeln(
        'use tokio_tungstenite::tungstenite::client::IntoClientRequest;',
      );
    }
    buf.writeln();
    buf.writeln('#[tokio::main]');
    buf.writeln('async fn main() {');
    buf.writeln('    let url = Url::parse("$url").unwrap();');
    if (headers.isNotEmpty) {
      buf.writeln('    let mut request = url.into_client_request().unwrap();');
      for (final h in headers) {
        buf.writeln(
          '    request.headers_mut().insert("${h.name}", "${h.value}".parse().unwrap());',
        );
      }
      buf.writeln(
        '    let (mut ws, _) = connect_async(request).await.expect("Failed to connect");',
      );
    } else {
      buf.writeln(
        '    let (mut ws, _) = connect_async(url).await.expect("Failed to connect");',
      );
    }
    buf.writeln('    println!("Connected!");');
    buf.writeln();
    buf.writeln(
      '    ws.send(Message::Text("Hello from APIDash".into())).await.unwrap();',
    );
    buf.writeln();
    buf.writeln('    while let Some(msg) = ws.next().await {');
    buf.writeln('        match msg.unwrap() {');
    buf.writeln('            Message::Text(t) => println!("Received: {}", t),');
    buf.writeln('            Message::Close(_) => break,');
    buf.writeln('            _ => {}');
    buf.writeln('        }');
    buf.writeln('    }');
    buf.writeln('}');
    return buf.toString();
  }
}

class WebSocketSwiftCodeGen {
  String getCode(WebSocketRequestModel model) {
    final buf = StringBuffer();
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;

    final headers = (model.requestHeaders ?? [])
        .asMap()
        .entries
        .where(
          (e) =>
              model.isHeaderEnabledList == null ||
              (model.isHeaderEnabledList!.length > e.key &&
                  model.isHeaderEnabledList![e.key]),
        )
        .map((e) => e.value)
        .where((h) => h.name.isNotEmpty)
        .toList();

    buf.writeln('import Foundation');
    buf.writeln();
    buf.writeln('let url = URL(string: "$url")!');
    if (headers.isNotEmpty) {
      buf.writeln('var request = URLRequest(url: url)');
      for (final h in headers) {
        buf.writeln(
          'request.setValue("${h.value}", forHTTPHeaderField: "${h.name}")',
        );
      }
      buf.writeln('let task = URLSession.shared.webSocketTask(with: request)');
    } else {
      buf.writeln('let task = URLSession.shared.webSocketTask(with: url)');
    }
    buf.writeln();
    buf.writeln('// Receive messages');
    buf.writeln('func receive() {');
    buf.writeln('    task.receive { result in');
    buf.writeln('        switch result {');
    buf.writeln('        case .success(let message):');
    buf.writeln('            if case .string(let text) = message {');
    buf.writeln('                print("Received: \\(text)")');
    buf.writeln('            }');
    buf.writeln('            receive() // keep listening');
    buf.writeln('        case .failure(let error):');
    buf.writeln('            print("Error: \\(error)")');
    buf.writeln('        }');
    buf.writeln('    }');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('task.resume()');
    buf.writeln('print("Connected!")');
    buf.writeln();
    buf.writeln('// Send a message');
    buf.writeln('task.send(.string("Hello from APIDash")) { error in');
    buf.writeln('    if let error = error { print("Send error: \\(error)") }');
    buf.writeln('}');
    buf.writeln();
    buf.writeln('receive()');
    buf.writeln('RunLoop.main.run()');
    return buf.toString();
  }
}

class WebSocketCurlCodeGen {
  String getCode(WebSocketRequestModel model) {
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;
    return 'curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" "$url"';
  }
}

class WebSocketHarCodeGen {
  String getCode(WebSocketRequestModel model) {
    return '{\n  "log": {\n    "version": "1.2",\n    "creator": {\n      "name": "APIDash",\n      "version": "1.0.0"\n    },\n    "entries": []\n  }\n}';
  }
}

class WebSocketJuliaCodeGen {
  String getCode(WebSocketRequestModel model) {
    final url = model.url.isEmpty ? 'ws://localhost:8080' : model.url;
    return 'using WebSockets\n\nWebSockets.open("$url") do ws\n    write(ws, "Hello APIDash")\n    msg = read(ws)\n    println("Received: ", String(msg))\nend';
  }
}

class WebSocketPhpCodeGen {
  String getCode(WebSocketRequestModel model) {
    return r"""<?php
require 'vendor/autoload.php';

\Ratchet\Client\connect('\$url')->then(function($conn) {
    $conn->on('message', function($msg) use ($conn) {
        echo "Received: {$msg}\n";
    });
    $conn->send('Hello APIDash!');
}, function ($e) {
    echo "Could not connect: {$e->getMessage()}\n";
});"""
        .replaceAll("\$url", model.url.isEmpty ? "localhost" : model.url);
  }
}
