import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'drawing_controller.dart';

import 'helper/ex_value_builder.dart';
import 'helper/get_size.dart';
import 'paint_contents/circle.dart';
import 'paint_contents/eraser.dart';
import 'paint_contents/rectangle.dart';
import 'paint_contents/simple_line.dart';
import 'paint_contents/smooth_line.dart';
import 'paint_contents/straight_line.dart';
import 'painter.dart';


typedef DefaultToolsBuilder = List<DefToolItem> Function(
  Type currType,
  DrawingController controller,
);



class DrawingBoard extends StatefulWidget {
  const DrawingBoard({
    super.key,
    required this.background,
    this.controller,
    this.difficultyOption = 0,
    this.showDefaultActions = false,
    this.showDefaultTools = false,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.clipBehavior = Clip.antiAlias,
    this.defaultToolsBuilder,
    this.boardClipBehavior = Clip.hardEdge,
    this.panAxis = PanAxis.free,
    this.boardBoundaryMargin,
    this.boardConstrained = false,
    this.maxScale = 20,
    this.minScale = 0.2,
    this.boardPanEnabled = true,
    this.boardScaleEnabled = true,
    this.boardScaleFactor = 200.0,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.transformationController,
    this.alignment = Alignment.topCenter,
  });


  final Widget background;


  final DrawingController? controller;


  final bool showDefaultActions;


  final bool showDefaultTools;


  final Function(PointerDownEvent pde)? onPointerDown;


  final Function(PointerMoveEvent pme)? onPointerMove;


  final Function(PointerUpEvent pue)? onPointerUp;


  final Clip clipBehavior;


  final DefaultToolsBuilder? defaultToolsBuilder;


  final Clip boardClipBehavior;

  final PanAxis panAxis;
  final EdgeInsets? boardBoundaryMargin;
  final bool boardConstrained;
  final double maxScale;
  final double minScale;
  final void Function(ScaleEndDetails)? onInteractionEnd;
  final void Function(ScaleStartDetails)? onInteractionStart;
  final void Function(ScaleUpdateDetails)? onInteractionUpdate;
  final bool boardPanEnabled;
  final bool boardScaleEnabled;
  final double boardScaleFactor;
  final TransformationController? transformationController;
  final AlignmentGeometry alignment;


  final int difficultyOption;

  static List<DefToolItem> defaultTools(
      Type currType, DrawingController controller) {
    return <DefToolItem>[
      DefToolItem(
          isActive: currType == SimpleLine,
          icon: Icons.edit,
          onTap: () => controller.setPaintContent(SimpleLine())),
      DefToolItem(
          isActive: currType == SmoothLine,
          icon: Icons.brush,
          onTap: () => controller.setPaintContent(SmoothLine())),
      DefToolItem(
          isActive: currType == StraightLine,
          icon: Icons.show_chart,
          onTap: () => controller.setPaintContent(StraightLine())),
      DefToolItem(
          isActive: currType == Circle,
          icon: CupertinoIcons.circle,
          onTap: () => controller.setPaintContent(Circle())),
      DefToolItem(
          isActive: currType == Rectangle,
          icon: CupertinoIcons.stop,
          onTap: () => controller.setPaintContent(Rectangle())),
      DefToolItem(
          isActive: currType == Eraser,

          icon: CupertinoIcons.bandage,
          onTap: () => controller.setPaintContent(Eraser())),
    ];
  }

  static List<DefToolItem> mediumTools(
      Type currType, DrawingController controller) {
    return <DefToolItem>[

      DefToolItem(
          isActive: currType == SimpleLine,
          icon: Icons.edit,
          onTap: () => controller.setPaintContent(SimpleLine())),
      DefToolItem(
          isActive: currType == SmoothLine,
          icon: Icons.brush,
          onTap: () => controller.setPaintContent(SmoothLine())),
      DefToolItem(
          isActive: currType == StraightLine,
          icon: Icons.show_chart,
          onTap: () => controller.setPaintContent(StraightLine())),
      DefToolItem(
          isActive: currType == Circle,
          icon: CupertinoIcons.circle,
          onTap: () => controller.setPaintContent(Circle())),

      DefToolItem(
          isActive: currType == Eraser,
          icon: CupertinoIcons.bandage,
          onTap: () => controller.setPaintContent(Eraser())),
    ];
  }

  static List<DefToolItem> hardTools(
      Type currType, DrawingController controller) {
    return <DefToolItem>[

      DefToolItem(
          isActive: currType == SimpleLine,
          icon: Icons.edit,
          onTap: () => controller.setPaintContent(SimpleLine())),
      DefToolItem(
          isActive: currType == SmoothLine,
          icon: Icons.brush,
          onTap: () => controller.setPaintContent(SmoothLine())),
      DefToolItem(
          isActive: currType == StraightLine,
          icon: Icons.show_chart,
          onTap: () => controller.setPaintContent(StraightLine())),

      DefToolItem(
          isActive: currType == Eraser,
          icon: CupertinoIcons.bandage,
          onTap: () => controller.setPaintContent(Eraser())),
    ];
  }


  static Widget buildDefaultActions(DrawingController controller) {
    return _DrawingBoardState.buildDefaultActions(controller);
  }
  static Widget buildDefaultTools(DrawingController controller,
      {DefaultToolsBuilder? defaultToolsBuilder, Axis axis = Axis.horizontal}) {
    return _DrawingBoardState.buildDefaultTools(controller,
        defaultToolsBuilder: defaultToolsBuilder, axis: axis);
  }


  static Widget buildMediumActions(DrawingController controller) {
    return _DrawingBoardState.buildMediumActions(controller);
  }


  static Widget buildMediumTools(DrawingController controller,
      {DefaultToolsBuilder? defaultToolsBuilder, Axis axis = Axis.horizontal}) {
    return _DrawingBoardState.buildMediumTools(controller,
        defaultToolsBuilder: defaultToolsBuilder, axis: axis);
  }

  static Widget buildHardActions(DrawingController controller) {
    return _DrawingBoardState.buildHardActions(controller);
  }

  static Widget buildHardTools(DrawingController controller,
      {DefaultToolsBuilder? defaultToolsBuilder, Axis axis = Axis.horizontal}) {
    return _DrawingBoardState.buildHardTools(controller,
        defaultToolsBuilder: defaultToolsBuilder, axis: axis);
  }


  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  late final DrawingController _controller =
      widget.controller ?? DrawingController();

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = InteractiveViewer(
      maxScale: widget.maxScale,
      minScale: widget.minScale,
      boundaryMargin: widget.boardBoundaryMargin ??
          EdgeInsets.all(MediaQuery.of(context).size.width),
      clipBehavior: widget.boardClipBehavior,
      panAxis: widget.panAxis,
      constrained: widget.boardConstrained,
      onInteractionStart: widget.onInteractionStart,
      onInteractionUpdate: widget.onInteractionUpdate,
      onInteractionEnd: widget.onInteractionEnd,
      scaleFactor: widget.boardScaleFactor,
      panEnabled: widget.boardPanEnabled,
      scaleEnabled: widget.boardScaleEnabled,
      transformationController: widget.transformationController,
      child: Align(alignment: widget.alignment, child: _buildBoard),
    );


      content = Column(
        children: <Widget>[
          Expanded(child: content),
          if (widget.difficultyOption == 0) buildDefaultActions(_controller),
          if (widget.difficultyOption == 0) buildDefaultTools(_controller, defaultToolsBuilder: widget.defaultToolsBuilder),

          if (widget.difficultyOption == 1) buildMediumActions(_controller),
          if (widget.difficultyOption == 1) buildMediumTools(_controller, defaultToolsBuilder: widget.defaultToolsBuilder),


          if (widget.difficultyOption == 2) buildHardActions(_controller),
          if (widget.difficultyOption == 2) buildHardTools(_controller, defaultToolsBuilder: widget.defaultToolsBuilder)

        ],
      );


    return Listener(
      onPointerDown: (PointerDownEvent pde) =>
          _controller.addFingerCount(pde.localPosition),
      onPointerUp: (PointerUpEvent pue) =>
          _controller.reduceFingerCount(pue.localPosition),
      onPointerCancel: (PointerCancelEvent pce) =>
          _controller.reduceFingerCount(pce.localPosition),
      child: content,
    );
  }


  Widget get _buildBoard {
    return RepaintBoundary(
      key: _controller.painterKey,
      child: ExValueBuilder<DrawConfig>(
        valueListenable: _controller.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) =>
            p.angle != n.angle || p.size != n.size,
        builder: (_, DrawConfig dc, Widget? child) {
          Widget c = child!;

          if (dc.size != null) {
            final bool isHorizontal = dc.angle.toDouble() % 2 == 0;
            final double max = dc.size!.longestSide;

            if (!isHorizontal) {
              c = SizedBox(width: max, height: max, child: c);
            }
          }

          return Transform.rotate(angle: dc.angle * pi / 2, child: c);
        },
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[_buildImage, _buildPainter],
          ),
        ),
      ),
    );
  }


  Widget get _buildImage => GetSize(
        onChange: (Size? size) => _controller.setBoardSize(size),
        child: widget.background,
      );


  Widget get _buildPainter {
    return ExValueBuilder<DrawConfig>(
      valueListenable: _controller.drawConfig,
      shouldRebuild: (DrawConfig p, DrawConfig n) => p.size != n.size,
      builder: (_, DrawConfig dc, Widget? child) {
        return SizedBox(
          width: dc.size?.width,
          height: dc.size?.height,
          child: child,
        );
      },
      child: Painter(
        drawingController: _controller,
        onPointerDown: widget.onPointerDown,
        onPointerMove: widget.onPointerMove,
        onPointerUp: widget.onPointerUp,
      ),
    );
  }


  static Widget buildDefaultActions(

      DrawingController controller) {
    double _colorOpacity = 1;
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
          valueListenable: controller.drawConfig,
          builder: (_, DrawConfig dc, ___) {
            return Row(
              children: <Widget>[
                SizedBox(
                  height: 24,
                  width: 160,
                  child: Slider(
                    value: dc.strokeWidth,
                    max: 50,
                    min: 1,
                    onChanged: (double v) =>
                        controller.setStyle(strokeWidth: v),
                  ),
                ),
                ColorPickerPopup(
                  difficulty: 0,
                  onColorSelected: (ui.Color selectedColor) {
                    controller.setStyle(color: selectedColor.withOpacity(_colorOpacity));
                  },
                ),

                IconButton(
                  icon: Icon(
                    CupertinoIcons.arrow_turn_up_left,
                    color: controller.canUndo() ? null : Colors.grey,
                  ),
                  onPressed: () => controller.undo(),
                ),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.arrow_turn_up_right,
                    color: controller.canRedo() ? null : Colors.grey,
                  ),
                  onPressed: () => controller.redo(),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.trash),
                  onPressed: () => controller.clear(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget buildMediumActions(DrawingController controller) {
    double _colorOpacity = 1;
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
            valueListenable: controller.drawConfig,
            builder: (_, DrawConfig dc, ___) {
              return Row(
                children: <Widget>[
                  SizedBox(
                    height: 24,
                    width: 160,
                    child: Slider(
                      value: dc.strokeWidth,
                      max: 50,
                      min: 1,
                      onChanged: (double v) =>
                          controller.setStyle(strokeWidth: v),
                    ),
                  ),
                  ColorPickerPopup(
                    difficulty: 1,
                    onColorSelected: (ui.Color selectedColor) {
                      controller.setStyle(color: selectedColor.withOpacity(_colorOpacity));
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.arrow_turn_up_left,
                      color: controller.canUndo() ? null : Colors.grey,
                    ),
                    onPressed: () => controller.undo(),
                  ),


                  IconButton(
                    icon: const Icon(CupertinoIcons.trash),
                    onPressed: () => controller.clear(),
                  ),
                ],
              );
            }),
      ),
    );
  }

  static Widget buildHardActions(DrawingController controller) {
    double _colorOpacity = 1;
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
            valueListenable: controller.drawConfig,
            builder: (_, DrawConfig dc, ___) {
              return Row(
                children: <Widget>[
                  SizedBox(
                    height: 24,
                    width: 160,
                    child: Slider(
                      value: dc.strokeWidth,
                      max: 50,
                      min: 1,
                      onChanged: (double v) =>
                          controller.setStyle(strokeWidth: v),
                    ),
                  ),
                  ColorPickerPopup(
                    difficulty: 2,
                    onColorSelected: (ui.Color selectedColor) {
                      controller.setStyle(color: selectedColor.withOpacity(_colorOpacity));
                    },
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash),
                    onPressed: () => controller.clear(),
                  ),
                ],
              );
            }),
      ),
    );
  }

  static Widget buildDefaultTools(
    DrawingController controller, {
    DefaultToolsBuilder? defaultToolsBuilder,
    Axis axis = Axis.horizontal,
  }) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: axis,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
          valueListenable: controller.drawConfig,
          shouldRebuild: (DrawConfig p, DrawConfig n) =>
              p.contentType != n.contentType,
          builder: (_, DrawConfig dc, ___) {
            final Type currType = dc.contentType;

            final List<Widget> children =
                (defaultToolsBuilder?.call(currType, controller) ??
                        DrawingBoard.defaultTools(currType, controller))
                    .map((DefToolItem item) => _DefToolItemWidget(item: item))
                    .toList();

            return axis == Axis.horizontal
                ? Row(children: children)
                : Column(children: children);
          },
        ),

      ),
    );
  }




  static Widget buildMediumTools(
      DrawingController controller, {
        DefaultToolsBuilder? defaultToolsBuilder,
        Axis axis = Axis.horizontal,
      }) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: axis,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
          valueListenable: controller.drawConfig,
          shouldRebuild: (DrawConfig p, DrawConfig n) =>
          p.contentType != n.contentType,
          builder: (_, DrawConfig dc, ___) {
            final Type currType = dc.contentType;

            final List<Widget> children =
            (defaultToolsBuilder?.call(currType, controller) ??
                DrawingBoard.mediumTools(currType, controller))
                .map((DefToolItem item) => _DefToolItemWidget(item: item))
                .toList();

            return axis == Axis.horizontal
                ? Row(children: children)
                : Column(children: children);
          },
        ),

      ),
    );
  }

  static Widget buildHardTools(
      DrawingController controller, {
        DefaultToolsBuilder? defaultToolsBuilder,
        Axis axis = Axis.horizontal,
      }) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: axis,
        padding: EdgeInsets.zero,
        child: ExValueBuilder<DrawConfig>(
          valueListenable: controller.drawConfig,
          shouldRebuild: (DrawConfig p, DrawConfig n) =>
          p.contentType != n.contentType,
          builder: (_, DrawConfig dc, ___) {
            final Type currType = dc.contentType;

            final List<Widget> children =
            (defaultToolsBuilder?.call(currType, controller) ??
                DrawingBoard.hardTools(currType, controller))
                .map((DefToolItem item) => _DefToolItemWidget(item: item))
                .toList();

            return axis == Axis.horizontal
                ? Row(children: children)
                : Column(children: children);
          },
        ),

      ),
    );
  }


}
class ColorPickerPopup extends StatefulWidget {
  final void Function(ui.Color color) onColorSelected;
  final int difficulty;

  const ColorPickerPopup({
    Key? key,
    required this.difficulty,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  _ColorPickerPopupState createState() => _ColorPickerPopupState();
}

class _ColorPickerPopupState extends State<ColorPickerPopup> {
  List<ui.Color> _getPalette() {
    // Define color palettes for each difficulty
    const List<ui.Color> fullPalette = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.grey,
    ];

    switch (widget.difficulty) {
      case 1:
        return [
          Colors.red,
          Colors.green,
          Colors.blue,
        ]; // Primary colors only
      case 2:
        return [
          Colors.red,
          Colors.blue,
        ]; // Minimal colors
      case 0:
      default:
        return fullPalette; // All colors
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ui.Color> customPalette = _getPalette();

    return PopupMenuButton<Color>(
      icon: const Icon(Icons.color_lens),
      offset: const Offset(0, -50), // Adjust popup position
      onSelected: (ui.Color value) {
        widget.onColorSelected(value);
      },
      itemBuilder: (_) {
        return [
          PopupMenuItem<ui.Color>(
            enabled: false, // Disable default item behavior
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Allow horizontal scrolling
              child: Row(
                children: customPalette.map((ui.Color color) {
                  return GestureDetector(
                    onTap: () {
                      widget.onColorSelected(color);
                      Navigator.of(context).pop(); // Close the popup menu
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      color: color,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ];
      },
    );
  }
}



class DefToolItem {
  DefToolItem({
    required this.icon,
    required this.isActive,
    this.onTap,
    this.color,
    this.activeColor = Colors.blue,
    this.iconSize,
  });

  final Function()? onTap;
  final bool isActive;

  final IconData icon;
  final double? iconSize;
  final Color? color;
  final Color activeColor;
}


class _DefToolItemWidget extends StatelessWidget {
  const _DefToolItemWidget({
    required this.item,
  });

  final DefToolItem item;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: item.onTap,
      icon: Icon(
        item.icon,
        color: item.isActive ? item.activeColor : item.color,
        size: item.iconSize,
      ),
    );
  }
}
