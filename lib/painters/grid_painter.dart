import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// GPU-accelerated grid painter using a tiled ImageShader
/// No external shader files needed - works as a library
class GridPainter extends CustomPainter {
  final ui.Image gridTile;
  final ui.ImageShader _shader;

  GridPainter({required this.gridTile})
    : _shader = ui.ImageShader(gridTile, TileMode.repeated, TileMode.repeated, Matrix4.identity().storage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = _shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => gridTile != oldDelegate.gridTile;
}

/// Widget that generates a grid tile and displays it tiled across the canvas
class ShaderGrid extends StatefulWidget {
  final Size size;
  final double gridSize;
  final double lineWidth;
  final Color lineColor;
  final Color backgroundColor;

  const ShaderGrid({
    required this.size,
    this.gridSize = 50.0,
    this.lineWidth = 1.0,
    this.lineColor = const Color(0x20000000),
    this.backgroundColor = const Color(0xFFF5F5F5),
    super.key,
  });

  @override
  State<ShaderGrid> createState() => _ShaderGridState();
}

class _ShaderGridState extends State<ShaderGrid> {
  ui.Image? _gridTile;

  @override
  void initState() {
    super.initState();
    _generateGridTile();
  }

  @override
  void didUpdateWidget(ShaderGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gridSize != widget.gridSize ||
        oldWidget.lineWidth != widget.lineWidth ||
        oldWidget.lineColor != widget.lineColor ||
        oldWidget.backgroundColor != widget.backgroundColor) {
      _generateGridTile();
    }
  }

  Future<void> _generateGridTile() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final tileSize = widget.gridSize;

    // Draw background
    final bgPaint = Paint()..color = widget.backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, tileSize, tileSize), bgPaint);

    // Draw grid lines
    final linePaint = Paint()
      ..color = widget.lineColor
      ..strokeWidth = widget.lineWidth
      ..style = PaintingStyle.stroke;

    // Right edge (will connect with next tile's left)
    canvas.drawLine(Offset(tileSize, 0), Offset(tileSize, tileSize), linePaint);
    // Bottom edge (will connect with next tile's top)
    canvas.drawLine(Offset(0, tileSize), Offset(tileSize, tileSize), linePaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(tileSize.toInt(), tileSize.toInt());

    if (mounted) {
      setState(() {
        _gridTile = image;
      });
    }
  }

  @override
  void dispose() {
    _gridTile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gridTile == null) {
      return Container(color: widget.backgroundColor, width: widget.size.width, height: widget.size.height);
    }

    return CustomPaint(
      size: widget.size,
      painter: GridPainter(gridTile: _gridTile!),
    );
  }
}
