import 'package:flutter/material.dart';
import '../models/index.dart';

/// Centralized layout constants and calculations for node positioning
class NodeLayout {
  /// Height of the node header section
  static const double headerHeight = 50;

  /// Vertical offset from header to content area
  static const double contentOffset = 20;

  /// Size of input/output connector circles
  static const double connectorSize = 20;

  /// Spacing between connectors
  static const double connectorSpacing = 15;

  /// Calculates the position for an output connector on a node
  static Offset outputConnectorPosition(Node node, int index) {
    final double indexOffset = index > 0
        ? (index * headerHeight) + headerHeight + contentOffset - 5
        : headerHeight + contentOffset + 10;
    return node.offset + Offset(node.size.width, indexOffset);
  }

  /// Calculates the position for an input connector on a node
  static Offset inputConnectorPosition(Node node, int index) {
    final double indexOffset = index > 0 ? index * headerHeight - 5 : contentOffset / 2;
    return node.offset + Offset(0, headerHeight + contentOffset + indexOffset);
  }

  /// Calculates the total height of a node including header and content offset
  static double totalNodeHeight(Node node) {
    return node.size.height + headerHeight + contentOffset;
  }

  /// Returns the bounding rectangle for a node
  static Rect nodeRect(Node node) {
    return Rect.fromLTWH(node.offset.dx, node.offset.dy, node.size.width, totalNodeHeight(node));
  }
}
