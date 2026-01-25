import 'package:flutter/material.dart';

import '../models/index.dart';
import '../controller/node_editor_controller.dart';
import '../utils/node_layout.dart';

/// Widget for rendering a column of input connectors
class InputConnectorColumn extends StatelessWidget {
  final Node node;
  final NodeEditorController controller;

  const InputConnectorColumn({required this.node, required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: NodeLayout.connectorSpacing,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: node.inputs.asMap().entries.map((entry) {
        final index = entry.key;
        final input = entry.value;
        return _InputConnector(input: input, index: index, node: node, controller: controller);
      }).toList(),
    );
  }
}

/// Widget for rendering a column of output connectors
class OutputConnectorColumn extends StatelessWidget {
  final Node node;
  final NodeEditorController controller;

  const OutputConnectorColumn({required this.node, required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: NodeLayout.connectorSpacing,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: node.outputs.asMap().entries.map((entry) {
        final index = entry.key;
        final output = entry.value;
        return _OutputConnector(output: output, index: index, node: node, controller: controller);
      }).toList(),
    );
  }
}

/// Individual input connector circle
class _InputConnector extends StatelessWidget {
  final Input input;
  final int index;
  final Node node;
  final NodeEditorController controller;

  const _InputConnector({required this.input, required this.index, required this.node, required this.controller});

  void _handleTap(TapDownDetails details) {
    if (controller.activeConnection != null) {
      // Complete connection to this input
      controller.addConnection(
        controller.activeConnection!
          ..endNode = node
          ..endIndex = index,
      );
    } else {
      // Check for existing connection to disconnect and re-drag
      var previousConnection = controller.connections.where(
        (conn) => conn.endNode?.uuid == node.uuid && conn.endIndex == index,
      );

      if (previousConnection.isNotEmpty) {
        var connection = previousConnection.first;
        final startPosition = NodeLayout.outputConnectorPosition(connection.startNode, connection.startIndex);

        controller.removeConnection(connection);
        controller.setActiveConnection(
          Connection(
            start: startPosition,
            end: details.globalPosition,
            startNode: connection.startNode,
            startIndex: connection.startIndex,
            endIndex: index,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: input.label,
      child: InkWell(
        onTapDown: _handleTap,
        child: Container(
          width: NodeLayout.connectorSize,
          height: NodeLayout.connectorSize,
          decoration: BoxDecoration(
            color: input.color,
            borderRadius: BorderRadius.circular(NodeLayout.connectorSize / 2),
          ),
        ),
      ),
    );
  }
}

/// Individual output connector circle
class _OutputConnector extends StatelessWidget {
  final Output output;
  final int index;
  final Node node;
  final NodeEditorController controller;

  const _OutputConnector({required this.output, required this.index, required this.node, required this.controller});

  void _handleTap(TapDownDetails details) {
    final offset = NodeLayout.outputConnectorPosition(node, index);
    controller.setActiveConnection(Connection(start: offset, end: offset, startNode: node, startIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: output.label,
      child: InkWell(
        onTapDown: _handleTap,
        child: Container(
          width: NodeLayout.connectorSize,
          height: NodeLayout.connectorSize,
          decoration: BoxDecoration(
            color: output.color,
            borderRadius: BorderRadius.circular(NodeLayout.connectorSize / 2),
          ),
        ),
      ),
    );
  }
}
