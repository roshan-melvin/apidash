import 'package:flutter/material.dart';

class WebSocketTemplatePanel extends StatefulWidget {
  final List<Map<String, dynamic>> templates;
  final bool initialIsSavingView;
  final String currentPayload;
  final Function() onClose;
  final Function(String name) onSave;
  final Function(int index) onDelete;
  final Function(Map<String, dynamic> template) onSelect;

  const WebSocketTemplatePanel({
    super.key,
    required this.templates,
    required this.initialIsSavingView,
    required this.currentPayload,
    required this.onClose,
    required this.onSave,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  State<WebSocketTemplatePanel> createState() => _WebSocketTemplatePanelState();
}

class _WebSocketTemplatePanelState extends State<WebSocketTemplatePanel> {
  final TextEditingController _nameCtrl = TextEditingController();
  int? _hoveredIndex;
  late bool _isSavingView;
  late List<Map<String, dynamic>> _localTemplates;

  @override
  void initState() {
    super.initState();
    _isSavingView = widget.initialIsSavingView;
    _localTemplates = List.from(widget.templates);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggleSaveView() {
    setState(() {
      _isSavingView = !_isSavingView;
    });
  }

  void _handleDelete(int index) {
    widget.onDelete(index);
    setState(() {
      _localTemplates.removeAt(index);
    });
  }

  bool _isDuplicate(String name) {
    name = name.trim().toLowerCase();
    for (var t in _localTemplates) {
      if ((t['name'] as String).toLowerCase() == name) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    final dividerColor = Colors.grey.withValues(alpha: 
      0.3,
    ); // Grey soft lines to reduce harshness

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          color: clr.surface,
          border: Border.all(color: dividerColor), // soft outer border
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: clr.shadow.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 8,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: _isSavingView
            ? _buildSaveView(clr, dividerColor)
            : _buildListView(clr, dividerColor),
      ),
    );
  }

  Widget _buildListView(ColorScheme clr, Color dividerColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Templates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: clr.onSurface,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _toggleSaveView,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New'),
                style: FilledButton.styleFrom(
                  backgroundColor: clr.primary, // Make button full blue
                  foregroundColor: clr.onPrimary,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: clr.onSurfaceVariant,
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),

        // List or Empty State
        Expanded(
          child: _localTemplates.isEmpty
              ? Center(
                  child: Text(
                    'No templates saved yet.',
                    style: TextStyle(color: clr.onSurfaceVariant, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _localTemplates.length,
                  itemBuilder: (ctx, i) {
                    final t = _localTemplates[i];
                    final isHovered = _hoveredIndex == i;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = i),
                      onExit: (_) => setState(() => _hoveredIndex = null),
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => widget.onSelect(t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 48,
                          color: isHovered
                              ? clr.secondaryContainer.withValues(alpha: 0.4)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.text_snippet_outlined,
                                size: 18,
                                color: isHovered
                                    ? clr.primary
                                    : clr.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t['name'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isHovered
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    color: isHovered
                                        ? clr.primary
                                        : clr.onSurface,
                                  ),
                                ),
                              ),
                              if (isHovered)
                                GestureDetector(
                                  onTap: () => _handleDelete(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: clr.errorContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: clr.onErrorContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Footer
        if (_localTemplates.isNotEmpty) ...[
          Divider(height: 1, thickness: 1, color: dividerColor),
          Container(
            height: 44,
            alignment: Alignment.center,
            child: Text(
              'Click any template to populate the message editor',
              style: TextStyle(fontSize: 12, color: clr.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveView(ColorScheme clr, Color dividerColor) {
    if (_localTemplates.length >= 20) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: clr.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Template limit reached (20).',
                    style: TextStyle(
                      color: clr.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Please delete an existing template before saving a new one.',
              style: TextStyle(color: clr.onSurfaceVariant, fontSize: 14),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () {
                  if (_localTemplates.isEmpty) {
                    widget.onClose();
                  } else {
                    _toggleSaveView();
                  }
                },
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      );
    }

    final isEmpty = widget.currentPayload.trim().isEmpty;
    final isDuplicate = _isDuplicate(_nameCtrl.text);
    final canSave =
        !isEmpty && !isDuplicate && _nameCtrl.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: clr.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Icon(Icons.save_outlined, size: 20, color: clr.primary),
              const SizedBox(width: 8),
              Text(
                'Save as Template',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: clr.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: clr.onSurfaceVariant,
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Template Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: clr.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'e.g., Auth Request',
                      filled: true,
                      fillColor: clr.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: clr.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (canSave) widget.onSave(_nameCtrl.text.trim());
                    },
                  ),
                ),
                if (isDuplicate) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.error_outline, size: 14, color: clr.error),
                      const SizedBox(width: 4),
                      Text(
                        'Name already exists',
                        style: TextStyle(color: clr.error, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Payload Preview',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: clr.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: clr.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: isEmpty
                        ? Center(
                            child: Text(
                              'Payload is empty',
                              style: TextStyle(
                                color: clr
                                    .onSurface, // Requested to change color to black
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Text(
                              widget.currentPayload.trim(),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: clr.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  if (_localTemplates.isEmpty) {
                    widget.onClose();
                  } else {
                    _toggleSaveView();
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(90, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: canSave
                    ? () => widget.onSave(_nameCtrl.text.trim())
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(90, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
