///
///@author xiaozhizhong
///@date 2020/4/17
///@description Expandable widget
///
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:expandable_widget_plus/res/expand_arrow.dart';

enum _ExpandMode { Manual, ShowHide, MaxHeight }

typedef ArrowBuilder = Widget Function(bool expand);

class ExpandableWidget extends StatefulWidget {
  ///In manual mode, it control the expand status
  ///In auto mode(ShowHide\MaxHeight), it decide Whether expand at the beginning or not, Default is false
  final bool expand;

  /// Color of the default arrow widget.
  final Color? arrowColor;

  /// Size of the default arrow widget. Default is 24.
  final double arrowSize;

  /// Custom arrow widget builder, will using [ExpandArrow] if this is null.
  final ArrowBuilder? arrowWidgetBuilder;

  /// If you use [arrowWidgetBuilder], you should provide the height of arrow widget manually
  final double? arrowWidgetHeight;

  /// How long the expanding animation takes. Default is 150ms.
  final Duration animationDuration;

  /// Child
  final Widget child;

  ///Max Height of widget that will show by default. Default is 100
  final double maxHeight;

  /// Control the animation position
  final Alignment alignment;

  ///Expand mode, {showHide} or {maxHeight} or {manual}
  final _ExpandMode mode;

  ///Manual control
  ///Show and hide child completely.
  const ExpandableWidget.manual(
      {required this.expand,
      required this.child,
      this.animationDuration = const Duration(milliseconds: 150),
      this.alignment = Alignment.topCenter,
      Key? key})
      : arrowColor = null,
        arrowSize = 24,
        arrowWidgetBuilder = null,
        arrowWidgetHeight = null,
        maxHeight = -1,
        mode = _ExpandMode.Manual,
        super(key: key);

  ///Auto control
  ///Show and hide child completely
  ///With a arrow at the bottom.
  const ExpandableWidget.showHide({
    Key? key,
    this.arrowColor,
    this.arrowSize = 24,
    this.arrowWidgetBuilder,
    this.arrowWidgetHeight,
    this.animationDuration = const Duration(milliseconds: 150),
    required this.child,
    this.expand = false,
    this.alignment = Alignment.topCenter,
  })  : maxHeight = 0,
        mode = _ExpandMode.ShowHide,
        super(key: key);

  ///Auto control
  ///Collapse child to max-height
  ///With a arrow at the bottom.
  ///If the child's height < [maxHeight], then will show child directly
  const ExpandableWidget.maxHeight({
    Key? key,
    this.arrowColor,
    this.arrowSize = 24,
    this.arrowWidgetBuilder,
    this.arrowWidgetHeight,
    this.animationDuration = const Duration(milliseconds: 150),
    required this.child,
    this.maxHeight = 100.0,
    this.expand = false,
    this.alignment = Alignment.topCenter,
  })  : mode = _ExpandMode.MaxHeight,
        super(key: key);

  @override
  _ExpandableWidgetState createState() => _ExpandableWidgetState();
}

class _ExpandableWidgetState extends State<ExpandableWidget>
    with SingleTickerProviderStateMixin {
  /// Expand status
  late bool _isExpanded;

  /// The height of arrow
  late double _arrowHeight;

  /// Whether is show hide Mode or max height mode.
  late bool _isShowHideMode;

  final _key = UniqueKey();

  @override
  void initState() {
    super.initState();
    if (widget.mode != _ExpandMode.Manual) {
      if (widget.arrowWidgetBuilder != null &&
          widget.arrowWidgetHeight == null) {
        throw FlutterError("Should provide the height of arrowWidget");
      }
      _isExpanded = widget.expand;
      _arrowHeight = widget.arrowWidgetHeight ?? 48;
      _isShowHideMode = widget.mode == _ExpandMode.ShowHide;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == _ExpandMode.Manual) return _buildManual();
    return _buildAuto();
  }

  ///build layout of manual mode
  _buildManual() {
    return ClipRect(
      child: AnimatedSize(
        alignment: widget.alignment,
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
        child: AnimatedSwitcher(
          duration: widget.animationDuration,
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: double.infinity),
              child: widget.expand
                  ? widget.child
                  : SizedBox(
                      key: _key,
                      width: double.infinity,
                      height: 0,
                    )),
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
            List<Widget> children = previousChildren;
            if (currentChild != null) {
              if (previousChildren.isEmpty)
                children = [currentChild];
              else {
                children = [
                  Positioned(
                    left: 0.0,
                    right: 0.0,
                    child: Container(
                      child: previousChildren[0],
                    ),
                  ),
                  Container(
                    child: currentChild,
                  ),
                ];
              }
            }
            return Stack(
              clipBehavior: Clip.none,
              children: children,
              alignment: widget.alignment,
            );
          },
        ),
      ),
    );
  }

  ///build layout of auto mode
  _buildAuto() {
    return AnimatedSize(
      duration: widget.animationDuration,
      reverseDuration: widget.animationDuration,
      alignment: widget.alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: !_isExpanded
                ? widget.maxHeight + _arrowHeight
                : double.infinity),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            LimitedBox(
              maxHeight: !_isExpanded ? widget.maxHeight : double.infinity,
              child: widget.child,
            ),
            Flexible(child: LayoutBuilder(
              builder: (_, size) {
                final height = size.biggest.height,
                    arrowWidgetBuilder = widget.arrowWidgetBuilder;
                return _isShowHideMode ||
                        height <= _arrowHeight ||
                        height.isInfinite
                    ? SizedBox(
                        width: double.infinity,
                        child: arrowWidgetBuilder != null
                            ? GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _onTap,
                                child: arrowWidgetBuilder(_isExpanded),
                              )
                            : ExpandArrow(
                                onPressed: (_) => _onTap(),
                                size: widget.arrowSize,
                                color: widget.arrowColor,
                                isExpanded: _isExpanded,
                              ),
                      )
                    : SizedBox();
              },
            )),
          ],
        ),
      ),
    );
  }

  /// User clicks the arrow
  void _onTap() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
}
