import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../controller/node_editor_controller.dart';
import '../painters/line_painter.dart';
import '../painters/grid_painter.dart';
import '../utils/node_layout.dart';
import 'node_base_widget.dart';
import 'context_menus.dart';

/// Main canvas widget for the node editor
class NodeCanvas extends StatefulWidget {
  final NodeEditorController controller;
  final Size size;
  final double zoom;
  final Color backgroundColor;
  final Color lineColor;

  const NodeCanvas({
    required this.controller,
    this.size = const Size(3000, 3000),
    this.zoom = 1.0,
    this.backgroundColor = Colors.white,
    this.lineColor = const Color(0x15000000),
    super.key,
  });

  // static Widget build({
  //   required NodeEditorController controller,
  //   Size size = const Size(3000, 3000),
  //   double zoom = 0.5,
  //   List<FloatingActionButton> buttons = const [],
  // }) {
  //   return NodeControls(
  //     notifier: controller,
  //     child: Scaffold(
  //       body: NodeCanvas(controller: controller, size: Size(3000, 3000), zoom: 0.5),
  //       floatingActionButton: ListenableBuilder(
  //         listenable: controller,
  //         builder: (ctx, _) {
  //           return Column(mainAxisAlignment: MainAxisAlignment.end, spacing: 10, children: buttons);
  //         },
  //       ),
  //     ),
  //   );
  // }

  @override
  State<NodeCanvas> createState() => _NodeCanvasState();
}

class _NodeCanvasState extends State<NodeCanvas> {
  final TransformationController _transformationController = TransformationController();
  String? _draggingNodeId;
  Offset _lastDragPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateCanvas);
    _transformationController.value = Matrix4.identity()
      ..scaleByVector3(vector.Vector3(widget.zoom, widget.zoom, widget.zoom));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCanvas);
    _transformationController.dispose();
    super.dispose();
  }

  void _updateCanvas() {
    setState(() {});
  }

  Offset _transformPosition(Offset screenPosition) {
    final Matrix4 transform = _transformationController.value;
    final Matrix4 invertedTransform = Matrix4.inverted(transform);
    final vector.Vector3 position = invertedTransform.transform3(
      vector.Vector3(screenPosition.dx, screenPosition.dy, 0),
    );
    return Offset(position.x, position.y);
  }

  void _handlePointerDown(PointerDownEvent event) {
    final canvasPosition = _transformPosition(event.localPosition);
    final node = widget.controller.findNodeAtPosition(canvasPosition);

    if (node != null) {
      setState(() {
        _draggingNodeId = node.uuid;
        _lastDragPosition = canvasPosition;
      });
    } else {
      widget.controller.removeActive();

      // Right mouse click happened
      if (event.buttons == 2) {
        _showCanvasContextMenu(event.localPosition, canvasPosition);
      }
    }
  }

  void _handlePointerHover(PointerHoverEvent event) {
    if (widget.controller.activeConnection != null) {
      final canvasPosition = _transformPosition(event.localPosition);
      setState(() {
        widget.controller.activeConnection?.end = canvasPosition;
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent details) {
    final canvasPosition = _transformPosition(details.localPosition);

    if (_draggingNodeId != null) {
      _handleNodeDrag(canvasPosition);
    } else if (details.buttons == 4) {
      _handlePan(details.delta);
    }
  }

  void _handleNodeDrag(Offset canvasPosition) {
    final delta = canvasPosition - _lastDragPosition;
    final node = widget.controller.nodes[_draggingNodeId];

    if (node != null) {
      widget.controller.setNodePosition(Offset(node.offset.dx + delta.dx, node.offset.dy + delta.dy), node);
      _lastDragPosition = canvasPosition;
      setState(() {});
    }
  }

  void _handlePan(Offset delta) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final currentTranslation = currentMatrix.getTranslation();
    final newTranslation = currentTranslation + vector.Vector3(delta.dx, delta.dy, 0);

    _transformationController.value = Matrix4.identity()
      ..translateByVector3(newTranslation)
      ..scaleByVector3(vector.Vector3(currentScale, currentScale, currentScale));
  }

  void _handlePointerUp(PointerUpEvent details) {
    setState(() {
      _draggingNodeId = null;
    });
  }

  void _showCanvasContextMenu(Offset localPosition, Offset canvasPosition) {
    NodeEditorContextMenus.showCanvasMenu(
      context: context,
      localPosition: localPosition,
      canvasPosition: canvasPosition,
      controller: widget.controller,
      onNodeCreate: _createNodeAtPosition,
    );
  }

  void _createNodeAtPosition(String typeName, Offset position) {
    final metadata = widget.controller.getNodeMetadata(typeName);
    if (metadata == null) return;

    final node = metadata.factory({"label": metadata.displayName});
    node.init(context).then((_) {
      widget.controller.addNode(node, position);
    });
  }

  /// Calculate canvas size that encompasses all nodes with padding
  Size _calculateCanvasSize() {
    double maxX = widget.size.width;
    double maxY = widget.size.height;

    for (final node in widget.controller.nodes.values) {
      final nodeRight = node.offset.dx + node.size.width + 200;
      final nodeBottom = node.offset.dy + NodeLayout.totalNodeHeight(node) + 200;
      if (nodeRight > maxX) maxX = nodeRight;
      if (nodeBottom > maxY) maxY = nodeBottom;
    }

    return Size(maxX, maxY);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Grid background covering entire viewport
            Positioned.fill(
              child: ShaderGrid(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                gridSize: 50,
                lineColor: widget.lineColor,
                backgroundColor: widget.backgroundColor,
              ),
            ),
            // Interactive canvas on top
            Listener(
              onPointerDown: _handlePointerDown,
              onPointerHover: _handlePointerHover,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.1,
                maxScale: 10,
                panEnabled: false,
                scaleEnabled: true,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                constrained: false,
                child: Builder(
                  builder: (context) {
                    final canvasSize = _calculateCanvasSize();
                    return SizedBox(
                      width: canvasSize.width,
                      height: canvasSize.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            painter: LinePainter(controller: widget.controller),
                            size: canvasSize,
                          ),
                          ...widget.controller.nodes.entries.map((item) {
                            final node = item.value;
                            return Positioned(
                              top: node.offset.dy,
                              left: node.offset.dx,
                              child: NodeBaseWidget(node: node, controller: widget.controller),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
