import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

class EqualSplitView extends StatefulWidget {
  const EqualSplitView({
    super.key,
    required this.leftWidget,
    required this.rightWidget,
  });

  final Widget leftWidget;
  final Widget rightWidget;

  @override
  State<EqualSplitView> createState() => _EqualSplitViewState();
}

class _EqualSplitViewState extends State<EqualSplitView> {
  late MultiSplitViewController _controller;
  double? _lastMinWidth;

  @override
  void initState() {
    super.initState();
    _controller = MultiSplitViewController(
      areas: [
        Area(id: "left", flex: 1),
        Area(id: "right", flex: 1),
      ],
    );
  }

  double getMinFractionWidth(double width) {
    if (width < 900) {
      return 0.9;
    } else if (width < 1000) {
      return 0.7;
    } else if (width < 1200) {
      return 0.5;
    } else {
      return 0.4;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: 3,
        dividerPainter: DividerPainters.background(
          color: Theme.of(context).colorScheme.surfaceContainer,
          highlightedColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          animationEnabled: false,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = getMinFractionWidth(constraints.maxWidth);

          if (_lastMinWidth != minWidth) {
            _lastMinWidth = minWidth;
            Future.microtask(() {
              if (mounted) {
                final areas = _controller.areas.toList();
                if (areas.length >= 2) {
                  _controller.areas = [
                    Area(
                      id: "left",
                      size: areas[0].size,
                      flex: areas[0].flex,
                      min: minWidth,
                    ),
                    Area(
                      id: "right",
                      size: areas[1].size,
                      flex: areas[1].flex,
                      min: minWidth,
                    ),
                  ];
                }
              }
            });
          }

          return MultiSplitView(
            controller: _controller,
            builder: (context, area) {
              return switch (area.id) {
                "left" => widget.leftWidget,
                "right" => widget.rightWidget,
                _ => const SizedBox.shrink(),
              };
            },
          );
        },
      ),
    );
  }
}
