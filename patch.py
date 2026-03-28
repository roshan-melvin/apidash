with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

text = text.replace(
"""      _updateState((state) => state.copyWith(
        isConnecting: false,
        isConnected: true,
        connectedUrl: requestModel.url,
        eventLog: [""",
"""      _updateState((state) => state.copyWith(
        isConnecting: false,
        isConnected: true,
        connectedUrl: requestModel.url,
        descriptors: _descriptors,
        eventLog: ["""
)

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)

