import re

with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

pattern = r'''_updateState\(\(state\) => state\.copyWith\(\s*eventLog: \[\s*\.\.\.state\.eventLog,\s*GrpcEvent\(timestamp: DateTime\.now\(\), type: GrpcEventType\.connect, description: 'Connected successfully to \$host:\$port\. Loading reflection\.\.\.'\)\s*\]\s*\)\);\s*_descriptors = await _reflectionService\.loadDescriptorsViaReflection\(\s*channel: _channel!,\s*host: host,\s*\)\.timeout\(const Duration\(seconds: 15\), onTimeout: \(\) \{\s*throw Exception\('Server Reflection timed out after 15 seconds\. Check port and TLS connection settings\.'\);\s*\}\);\s*if \(requestModel\.serviceName\.isNotEmpty && requestModel\.methodName\.isNotEmpty\) \{\s*_methodSignature = _reflectionService\.extractMethodSignature\(\s*serviceName: requestModel\.serviceName,\s*methodName: requestModel\.methodName,\s*descriptors: _descriptors!,\s*\);\s*\}\s*_updateState\(\(state\) => state\.copyWith\(\s*isConnecting: false,\s*isConnected: true,\s*connectedUrl: requestModel\.url,\s*descriptors: _descriptors,\s*eventLog: \[\s*\.\.\.state\.eventLog,\s*GrpcEvent\(timestamp: DateTime\.now\(\), type: GrpcEventType\.connect, description: 'Reflection descriptors loaded successfully\.'\)\s*\]\s*\)\);'''

new_block = """if (requestModel.descriptorSource == GrpcDescriptorSource.reflection) {
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
              GrpcEvent(timestamp: DateTime.now(), type: GrpcEventType.connect, description: 'Connected successfully to $host:$port. (Server Reflection off)')
            ]
          ));
        }"""

print("Match found?", re.search(pattern, text) != None)

new_text = re.sub(pattern, new_block, text)

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(new_text)
