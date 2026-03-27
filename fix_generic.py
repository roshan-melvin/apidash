import sys
content = open('lib/services/grpc_service.dart', 'r').read()
start_marker = "        final response = call.response;\n        final responseData = await response;\n\n"
end_marker = "        _updateState((state) => state.copyWith(\n          messages:\n            [\n              ...state.messages,\n              GrpcMessage(\n                payload: String.fromCharCodes(response),\n                timestamp: DateTime.now(),\n                isIncoming: true,\n              )\n            ],\n          eventLog:\n            [\n              ...state.eventLog,\n              GrpcEvent(\n                timestamp: DateTime.now(),\n                type: GrpcEventType.receive,\n                description: 'Received raw response',\n              )\n            ]\n        ));"

new_send = """        call.response.listen((data) {
          _updateState((state) => state.copyWith(
            messages: [
              ...state.messages,
              GrpcMessage(
                payload: String.fromCharCodes(data),
                timestamp: DateTime.now(),
                isIncoming: true,
              )
            ],
            eventLog: [
              ...state.eventLog,
              GrpcEvent(
                timestamp: DateTime.now(),
                type: GrpcEventType.receive,
                description: 'Received raw response chunk',
              )
            ]
          ));
        }, onError: (e) {
          _updateState((state) => state.copyWith(
            error: e.toString(),
            eventLog: [
              ...state.eventLog,
              GrpcEvent(
                timestamp: DateTime.now(),
                type: GrpcEventType.error,
                description: 'Error receiving response stream: $e',
              )
            ]
          ));
        });
"""

content = content[:content.find(start_marker)] + new_send + content[content.find(end_marker) + len(end_marker):]

open('lib/services/grpc_service.dart', 'w').write(content)
