with open('lib/services/grpc_reflection_service.dart', 'r') as f:
    text = f.read()

# Replace _listServices
old_list_services = '''    final req = $reflection.ServerReflectionRequest()
      ..host = host
      ..listServices = '*';
    final responseStream = client.serverReflectionInfo(Stream.value(req));
    await for (final resp in responseStream) {
      if (resp.hasListServicesResponse()) {
        return resp.listServicesResponse.service
            .map((s) => s.name)
            .where((s) => s.isNotEmpty)
            .toList(growable: false);
      }
      if (resp.hasErrorResponse()) {
        throw GrpcReflectionException('Reflection listServices failed: ${resp.errorResponse.errorMessage}');
      }
    }
    return const [];
  }'''

new_list_services = '''    final req = $reflection.ServerReflectionRequest()
      ..host = host
      ..listServices = '*';
    final controller = StreamController<$reflection.ServerReflectionRequest>();
    controller.add(req);
    final responseStream = client.serverReflectionInfo(controller.stream);
    try {
      await for (final resp in responseStream) {
        if (resp.hasListServicesResponse()) {
          return resp.listServicesResponse.service
              .map((s) => s.name)
              .where((s) => s.isNotEmpty)
              .toList(growable: false);
        }
        if (resp.hasErrorResponse()) {
          throw GrpcReflectionException('Reflection listServices failed: ${resp.errorResponse.errorMessage}');
        }
      }
    } finally {
      controller.close();
    }
    return const [];
  }'''

text = text.replace(old_list_services, new_list_services)

# Replace _fetchDescriptorsForSymbol
old_fetch = '''    final req = $reflection.ServerReflectionRequest()
      ..host = host
      ..fileContainingSymbol = symbol;

    final responseStream = client.serverReflectionInfo(Stream.value(req));
    await for (final resp in responseStream) {
      if (resp.hasFileDescriptorResponse()) {
        for (final fdBytes in resp.fileDescriptorResponse.fileDescriptorProto) {
          final fd = $descriptor.FileDescriptorProto.fromBuffer(fdBytes);
          if (!descriptorMap.containsKey(fd.name)) {
            descriptorMap[fd.name] = fd;
          }
          for (final dep in fd.dependency) {
            if (!descriptorMap.containsKey(dep)) {
              await _resolveDescriptorsForFile(client, dep, descriptorMap, host);
            }
          }
        }
      } else if (resp.hasErrorResponse()) {
        throw GrpcReflectionException('Reflection symbol lookup failed: ${resp.errorResponse.errorMessage}');
      }
    }
  }'''

new_fetch = '''    final req = $reflection.ServerReflectionRequest()
      ..host = host
      ..fileContainingSymbol = symbol;

    final controller = StreamController<$reflection.ServerReflectionRequest>();
    controller.add(req);
    final responseStream = client.serverReflectionInfo(controller.stream);
    
    try {
      await for (final resp in responseStream) {
        if (resp.hasFileDescriptorResponse()) {
          for (final fdBytes in resp.fileDescriptorResponse.fileDescriptorProto) {
            final fd = $descriptor.FileDescriptorProto.fromBuffer(fdBytes);
            if (!descriptorMap.containsKey(fd.name)) {
              descriptorMap[fd.name] = fd;
            }
            for (final dep in fd.dependency) {
              if (!descriptorMap.containsKey(dep)) {
                await _resolveDescriptorsForFile(client, dep, descriptorMap, host);
              }
            }
          }
          break; // Stop after getting the response to prevent hanging
        } else if (resp.hasErrorResponse()) {
          throw GrpcReflectionException('Reflection symbol lookup failed: ${resp.errorResponse.errorMessage}');
        }
      }
    } finally {
      controller.close();
    }
  }'''

text = text.replace(old_fetch, new_fetch)

# Replace _resolveDescriptorsForFile
old_resolve = '''    final req = $reflection.ServerReflectionRequest()
      ..host = host
      ..fileByFilename = filename;

    final responseStream = client.serverReflectionInfo(Stream.value(req));

    await for (final resp in responseStream) {
      if (resp.hasFileDescriptorResponse()) {
        for (final fdBytes in resp.fileDescriptorResponse.fileDescriptorProto) {
          final fd = $descriptor.FileDescriptorProto.fromBuffer(fdBytes);
          descriptorMap[fd.name] = fd;
        }
      }
    }
  }'''

new_resolve = '''    final req = $reflection.ServerReflectionRequest()
      ..host = host
      ..fileByFilename = filename;

    final controller = StreamController<$reflection.ServerReflectionRequest>();
    controller.add(req);
    final responseStream = client.serverReflectionInfo(controller.stream);

    try {
      await for (final resp in responseStream) {
        if (resp.hasFileDescriptorResponse()) {
          for (final fdBytes in resp.fileDescriptorResponse.fileDescriptorProto) {
            final fd = $descriptor.FileDescriptorProto.fromBuffer(fdBytes);
            descriptorMap[fd.name] = fd;
          }
          break;
        }
      }
    } finally {
      controller.close();
    }
  }'''

text = text.replace(old_resolve, new_resolve)

# Ensure StreamController is imported if not already. Although dart:async is imported.
if "import 'dart:async';" not in text:
    text = "import 'dart:async';\n" + text

with open('lib/services/grpc_reflection_service.dart', 'w') as f:
    f.write(text)
