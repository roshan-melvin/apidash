import re

path = 'lib/widgets/mqtt/mqtt_response_pane.dart'
with open(path, 'r') as f:
    text = f.read()

old_message_tile = """class _MessageTile extends StatelessWidget {
  final MQTTMessage message;

  const _MessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final bg = message.isIncoming
        ? clr.secondaryContainer.withAlpha(150)
        : clr.primaryContainer.withAlpha(150);
    final borderClr = message.isIncoming ? clr.secondary : clr.primary;
    final icon = message.isIncoming ? Icons.arrow_downward : Icons.arrow_upward;
    final label = message.isIncoming ? 'IN' : 'OUT';

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
                        color: clr.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              kHSpacer8,
              Expanded(
                child: Text(
                  message.topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                _timeFmt.format(message.timestamp),
                style: TextStyle(fontSize: 10, color: clr.outline),
              ),
            ],
          ),
          kVSpacer8,
          SelectableText(
            message.payload.isEmpty ? '(empty)' : message.payload,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }
}"""

new_message_tile = """class _MessageTile extends StatelessWidget {
  final MQTTMessage message;

  const _MessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final clrScheme = Theme.of(context).colorScheme;
    final isIncoming = message.isIncoming;
    
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
                  Row(
                    children: [
                      Text(
                        isIncoming ? 'IN' : 'OUT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      kHSpacer8,
                      Text(
                        message.topic,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _timeFmt.format(message.timestamp),
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
                  ),
                ],
              ),
              kVSpacer4,
              SelectableText(
                message.payload.isEmpty ? '(empty)' : message.payload,
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}"""

if old_message_tile in text:
    text = text.replace(old_message_tile, new_message_tile)
else:
    print('Failed to find old message tile in mqtt')

with open(path, 'w') as f:
    f.write(text)
