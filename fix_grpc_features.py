import re

with open('lib/widgets/grpc_response_pane.dart', 'r') as f:
    text = f.read()

# 1. Update _MessageBubble
text = re.sub(r'class _MessageBubble extends StatelessWidget \{[\s\S]*?\}\n\}', '''class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final GrpcMessage msg;

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final isIncoming = msg.isIncoming;
    final bg = isIncoming
        ? clr.secondaryContainer
        : clr.primaryContainer;
    final borderClr = isIncoming ? clr.secondary : clr.primary;
    final icon = isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    final label = isIncoming ? 'IN' : 'OUT';

    return Align(
      alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isIncoming ? 0 : 12),
              bottomRight: Radius.circular(isIncoming ? 12 : 0),
            ),
            border: Border.all(color: borderClr.withAlpha(50)),
          ),
          padding: kP8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: borderClr.withAlpha(200),
                      borderRadius: kBorderRadius4,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 10, color: clr.onPrimary),
                        kHSpacer4,
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: clr.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  kHSpacer8,
                  const Spacer(),
                  Text(
                    _timeFmt.format(msg.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: clr.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              kVSpacer8,
              SelectableText(
                msg.payload,
                style: TextStyle(
                  color: clr.onSurface,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}''', text)

with open('lib/widgets/grpc_response_pane.dart', 'w') as f:
    f.write(text)
