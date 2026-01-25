import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controller/node_editor_controller.dart';

/// Custom painter for drawing connection lines between nodes
class LinePainter extends CustomPainter {
  final NodeEditorController controller;

  LinePainter({required this.controller});

  final Paint _linePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw active connection being dragged
    if (controller.activeConnection != null) {
      _drawBezierCurve(canvas, controller.activeConnection!.start, controller.activeConnection!.end);
    }

    // Draw all established connections
    for (final conn in controller.connections) {
      _drawBezierCurve(canvas, conn.start, conn.end);
    }
  }

  void _drawBezierCurve(Canvas canvas, Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Calculate horizontal offset for control points
    // Minimum offset ensures curves look good even for short distances
    final dx = (end.dx - start.dx).abs();
    final offset = math.max(50.0, dx * 0.4);

    // Control points extend horizontally from start and end
    // This creates the characteristic Blender-style S-curve
    final controlPoint1 = Offset(start.dx + offset, start.dy);
    final controlPoint2 = Offset(end.dx - offset, end.dy);

    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, end.dx, end.dy);

    canvas.drawPath(path, _linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
