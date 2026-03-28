import re

with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

# Add descriptors to GrpcConnectionState
text = re.sub(
    r'(final String\? connectedUrl;\n\s*final List<GrpcMessage> messages;\n\s*final List<GrpcEvent> eventLog;)',
    r'\1\n  final Map<String, $descriptor.FileDescriptorProto>? descriptors;',
    text,
    count=1
)

text = re.sub(
    r'(this\.eventLog = const \[\],\n\s*\}\);)',
    r'this.eventLog = const [],\n    this.descriptors,\n  });',
    text,
    count=1
)

text = re.sub(
    r'(List<GrpcEvent>\? eventLog,\n\s*\}\) {)',
    r'List<GrpcEvent>? eventLog,\n    Map<String, $descriptor.FileDescriptorProto>? descriptors,\n  }) {',
    text,
    count=1
)

text = re.sub(
    r'(eventLog: eventLog \?\? this\.eventLog,\n\s*\);)',
    r'\1'.replace(');', '  descriptors: descriptors ?? this.descriptors,\n    );'),
    text,
    count=1
)

# Update _updateState in connect after loading descriptors
text = re.sub(
    r"(\s*_descriptors = await _reflectionService\.loadDescriptorsViaReflection\(\n\s*channel: _channel!,\n\s*host: host,\n\s*\);\n\s*if \(_descriptors \!= null\) \{\n\s*_updateState\(\(state\) => state\.copyWith\(\n\s*eventLog: \[)",
    r"\1".replace("eventLog: [", "descriptors: _descriptors,\n          eventLog: ["),
    text,
    count=1
)

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)

