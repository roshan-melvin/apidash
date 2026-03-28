with open('lib/services/grpc_service.dart', 'r') as f:
    text = f.read()

text = text.replace(
"""      messages: messages ?? this.messages,
      eventLog: eventLog ?? this.eventLog,
    );
  }
}""",
"""      messages: messages ?? this.messages,
      eventLog: eventLog ?? this.eventLog,
      descriptors: descriptors ?? this.descriptors,
    );
  }
}""")

with open('lib/services/grpc_service.dart', 'w') as f:
    f.write(text)

