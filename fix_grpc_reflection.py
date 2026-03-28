with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

old_block = """        _updateState((state) => state.copyWith(
          eventLog: [
            ...state.eventLog,
            GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.connect, description: 'Connected successfully to $host:$port. Loading reflection...')
          ]
        ));

        _descriptors = await _reflectionService.loadDescriptorsViaReflection(
          channel: _channel!,
          host: host,
        ).timeout(const Duration(seconds: 15), onTimeout: () {
          throw Exception('Server Reflection timed out after 15 seconds. Check port and TLS connection settings.');
        });

        if (requestModel.serviceName.isNotEmpty && requestModel.methodName.isNotEmpty) {
          _methodSignature = _reflectionService.extractMethodSignature(
            serviceName: requestModel.serviceName,
            methodName: requestModel.methodName,
            descriptors: _descriptors!,
          );
        }

        _updateState((state) => state.copyWith(
          isConnecting: false,
          isConnected: true,
          connectedUrl: requestModel.url,
          descriptors: _descriptors,
          eventLog: [
            ...state.eventLog,
            GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.connect, description: 'Reflection descriptors loaded successfully.')
          ]
        ));"""

new_block = """        if (requestModel.descriptorSource == GrpcDescriptorSource.reflection) {
          _updateState((state) => state.copyWith(
            eventLog: [
              ...state.eventLog,
              GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.connect, description: 'Connected successfully to $host:$port. Loading reflection...')
            ]
          ));

          _descriptors = await _reflectionService.loadDescriptorsViaReflection(
            channel: _channel!,
            host: host,
          ).timeout(const Duration(seconds: 15), onTimeout: () {
            throw Exception('Server Reflection timed out after 15 seconds. Check port and TLS connection settings.');
          });

          if (requestModel.serviceName.isNotEmpty && requestModel.methodName.isNotEmpty) {
            _methodSignature = _reflectionService.extractMethodSignature(
              serviceName: requestModel.serviceName,
              methodName: requestModel.methodName,
              descriptors: _descriptors!,
            );
          }

          _updateState((state) => state.copyWith(
            isConnecting: false,
            isConnected: true,
            connectedUrl: requestModel.url,
            descriptors: _descriptors,
            eventLog: [
              ...state.eventLog,
              GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.connect, description: 'Reflection descriptors loaded successfully.')
            ]
          ));
        } else {
          _updateState((state) => state.copyWith(
            isConnecting: false,
            isConnected: true,
            connectedUrl: requestModel.url,
            eventLog: [
              ...state.eventLog,
              GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.connect, description: 'Connected successfully to $host:$port. (Server Reflection is off)')
            ]
          ));
        }"""

text = text.replace(old_block, new_block)

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)
