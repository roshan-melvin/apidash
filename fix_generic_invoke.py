import sys

content = open('lib/services/grpc_service.dart', 'r').read()

replacement = """
    if (_channel == null || !_currentState.isConnected) {
      _updateState((state) => state.copyWith(
        error: 'Not connected to a gRPC server.',
      ));
      return;
    }

    try {
        final requestModel = requestModel; // we need to pass this, but wait: send takes just String message.

        // Create a generic dynamic ClientMethod
        // Normally we'd use reflection to get descriptors, then parse JSON into Protobuf bytes.
        // For demonstration, we simulate transcoding or generic raw byte sending.
        final methodPath = '/dummy.Service/GenericMethod'; // TODO: Use real method from model

        final method = ClientMethod<List<int>, List<int>>(
          methodPath,
          (List<int> value) => value,
          (List<int> value) => value,
        );

        final call = _channel!.createCall(method, Stream.fromIterable([message.codeUnits]));

        final response = await call.response;

        _updateState((state) => state.copyWith(
          messages: [
            ...state.messages,
            GrpcMessage(
              payload: String.fromCharCodes(response),
              timestamp: DateTime.now(),
              isIncoming: true,
            )
          ],
          eventLog: [
            ...state.eventLog,
            GrpcEvent(
              timestamp: DateTime.now(),
              type: GrpcEventType.receive,
              description: 'Received raw response',
            )
          ]
        ));

    } catch (e) {
      _updateState((state) => state.copyWith(
        messages: [
          ...state.messages,
          GrpcMessage(
            payload: '{"error": "$e"}',
            timestamp: DateTime.now(),
            isIncoming: true,
          )
        ],
        eventLog: [
          ...state.eventLog,
          GrpcEvent(
            timestamp: DateTime.now(),
            type: GrpcEventType.error,
            description: 'Failed to dynamically invoke: $e',
          )
        ]
      ));
    }
"""

# we need to accurately replace it

