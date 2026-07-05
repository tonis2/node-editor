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

  /// Vertical center of the connector at [index], measured from the node's top.
  ///
  /// Must mirror the real widget layout in [NodeBaseWidget]/[ConnectorRow]:
  /// header, then a [contentOffset] top margin, then a [Column] of connector
  /// circles ([connectorSize] tall) separated by [connectorSpacing]. Using
  /// [headerHeight] as the per-index step (the previous approach) only matched
  /// for the first two ports and drifted for every port after that, so moving a
  /// node snapped its connections to the wrong spots.
  static double _connectorCenterY(int index) {
    return headerHeight + contentOffset + connectorSize / 2 + index * (connectorSize + connectorSpacing);
  }

  /// Calculates the position for an output connector on a node
  static Offset outputConnectorPosition(Node node, int index) {
    return node.offset + Offset(node.size.width, _connectorCenterY(index));
  }

  /// Calculates the position for an input connector on a node
  static Offset inputConnectorPosition(Node node, int index) {
    return node.offset + Offset(0, _connectorCenterY(index));
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
