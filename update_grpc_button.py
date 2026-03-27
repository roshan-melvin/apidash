import re

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/url_card.dart', 'r') as f:
    text = f.read()

# I will find `class GrpcInvokeButton` and replace its definition

start_str = "class GrpcInvokeButton extends ConsumerStatefulWidget {"
end_str = "return FilledButton.icon("
new_code = '''class GrpcInvokeButton extends ConsumerStatefulWidget {
  const GrpcInvokeButton({super.key});

  @override
  ConsumerState<GrpcInvokeButton> createState() => _GrpcInvokeButtonState();
}

class _GrpcInvokeButtonState extends ConsumerState<GrpcInvokeButton> {
  void _invoke() {
    final activeRequestModel = ref.read(grpcRequestProvider);
    ref.read(grpcServiceProvider).connect(activeRequestModel);
  }

  void _disconnect() {
    ref.read(grpcServiceProvider).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final grpcState = ref.watch(grpcStateProvider);
    final isConnected = grpcState.value?.isConnected ?? false;
    final isConnecting = grpcState.value?.isConnecting ?? false;

    if (isConnected || isConnecting) {
      return FilledButton.icon(
        onPressed: _disconnect,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        icon: isConnecting
            ? Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onError,
                ),
              )
            : const Icon(Icons.stop),
        label: Text(isConnecting ? "Connecting" : "Disconnect"),
      );
    }
    
    return FilledButton.icon('''

text = text.replace(start_str + text.split(start_str)[1].split(end_str)[0] + end_str, new_code)

with open('/home/rocroshan/Desktop/GSOC/apidash/lib/screens/home_page/editor_pane/url_card.dart', 'w') as f:
    f.write(text)

