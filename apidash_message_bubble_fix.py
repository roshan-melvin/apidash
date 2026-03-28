import re

path = 'lib/widgets/websocket/websocket_response_pane.dart'
with open(path, 'r') as f:
    text = f.read()

old_message_bubble = """class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final WebSocketMessage msg;

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final bg = msg.isIncoming
        ? clr.secondaryContainer.withAlpha(150)
        : clr.primaryContainer.withAlpha(150);
    final borderClr = msg.isIncoming ? clr.secondary : clr.primary;
    final icon = msg.isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    final label = msg.isIncoming ? 'IN' : 'OUT';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: kBorderRadius8,
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
                          color: clr.onPrimary),
                    ),
                  ],
                ),
              ),
              kHSpacer8,
              const Spacer(),
              Text(
                _timeFmt.format(msg.timestamp),
                style: TextStyle(fontSize: 10, color: clr.outline),
              ),
            ],
          ),
          kVSpacer8,
          SelectableText(
            msg.payload.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }
}"""

new_message_bubble = """class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final WebSocketMessage msg;

  @override
  Widget build(BuildContext context) {
    final clrScheme = Theme.of(context).colorScheme;
    final isIncoming = msg.isIncoming;
    
    // Chat bubble alignment
    final alignment = isIncoming ? Alignment.centerLeft : Alignment.centerRight;
    final bubbleColor = isIncoming ? clrScheme.secondaryContainer : clrScheme.primaryContainer;
    final textColor = isIncoming ? clrScheme.onSecondaryContainer : clrScheme.onPrimaryContainer;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isIncoming ? Radius.zero : const Radius.circular(12),
      bottomRight: isIncoming ? const Radius.circular(12) : Radius.zero,
    );

    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: Container(
          padding: kP8,
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isIncoming ? 'IN' : 'OUT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _timeFmt.format(msg.timestamp),
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
                  ),
                ],
              ),
              kVSpacer4,
              SelectableText(
                msg.payload.toString(),
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}"""

text = text.replace(old_message_bubble, new_message_bubble)

with open(path, 'w') as f:
    f.write(text)

