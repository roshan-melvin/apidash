import re

with open('lib/widgets/grpc_response_pane.dart', 'r') as f:
    content = f.read()

# 1. Update text fields to have light mode specific styling

textfield_msg_old = """                    child: TextField(
                      controller: _msgFilterCtrl,
                      onChanged: (v) => setState(() => _filterString = v),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Filter payload...',
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                        ),"""

textfield_msg_new = """                    child: TextField(
                      controller: _msgFilterCtrl,
                      onChanged: (v) => setState(() => _filterString = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.light ? Colors.white : null,
                        isDense: true,
                        hintText: 'Filter payload...',
                        prefixIcon: const Icon(Icons.search, size: 16),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: kBorderRadius8,
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),"""

content = content.replace(textfield_msg_old, textfield_msg_new)

textfield_event_old = """              child: TextField(
                controller: _eventFilterCtrl,
                onChanged: (v) => setState(() => _filterEventString = v),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Filter events...',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(borderRadius: kBorderRadius8),"""

textfield_event_new = """              child: TextField(
                controller: _eventFilterCtrl,
                onChanged: (v) => setState(() => _filterEventString = v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.light ? Colors.white : null,
                  isDense: true,
                  hintText: 'Filter events...',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: kBorderRadius8,
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: kBorderRadius8,
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),"""

content = content.replace(textfield_event_old, textfield_event_new)

# 2. Update DataTable2 rows to have status colors

datarow_old = """      rows: events.reversed.map((e) {
        return DataRow(
          cells: ["""

datarow_new = """      rows: events.reversed.map((e) {
        return DataRow(
          color: WidgetStateProperty.resolveWith<Color?>((states) {
            Color? c;
            switch (e.type) {
              case GrpcEventType.connect:
                c = clr.primaryContainer.withAlpha(50);
                break;
              case GrpcEventType.disconnect:
              case GrpcEventType.error:
                c = clr.errorContainer.withAlpha(50);
                break;
              default:
                break;
            }
            if (states.contains(WidgetState.hovered)) {
              return c?.withAlpha(100) ??
                  clr.surfaceContainerHighest.withAlpha(50);
            }
            return c;
          }),
          cells: ["""

content = content.replace(datarow_old, datarow_new)

with open('lib/widgets/grpc_response_pane.dart', 'w') as f:
    f.write(content)

