with open('lib/providers/grpc_providers.dart', 'r') as f:
    text = f.read()

text = text.replace(
"""final grpcStateProvider = StreamProvider.autoDispose<GrpcConnectionState>((ref) {
  return ref.watch(grpcServiceProvider).stateStream;
});""",
"""final grpcStateProvider = StreamProvider.autoDispose<GrpcConnectionState>((ref) async* {
  final service = ref.watch(grpcServiceProvider);
  yield service.currentState;
  yield* service.stateStream;
});""")

with open('lib/providers/grpc_providers.dart', 'w') as f:
    f.write(text)

