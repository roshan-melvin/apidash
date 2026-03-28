with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

old_ref_call = '''      _descriptors = await _reflectionService.loadDescriptorsViaReflection(
        channel: _channel!,
        host: host,
        
      );'''

new_ref_call = '''      _descriptors = await _reflectionService.loadDescriptorsViaReflection(
        channel: _channel!,
        host: host,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Server Reflection timed out after 15 seconds. Check port and TLS connection settings.');
      });'''

text = text.replace(old_ref_call, new_ref_call)

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)
