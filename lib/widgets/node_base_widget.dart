import 'package:flutter/material.dart';
import '../models/index.dart';
import '../controller/node_editor_controller.dart';
import '../utils/node_layout.dart';
import 'connector_row.dart';
import 'context_menus.dart';

/// Widget that renders the visual representation of a node
class NodeBaseWidget extends StatelessWidget {
  final Node node;
  final NodeEditorController controller;

  const NodeBaseWidget({required this.node, required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onSecondaryTapDown: (details) {
        NodeEditorContextMenus.showNodeMenu(
          context: context,
          globalPosition: details.globalPosition,
          node: node,
          controller: controller,
        );
      },
      child: Container(
        width: node.size.width,
        height: NodeLayout.totalNodeHeight(node),
        decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            _NodeHeader(node: node),
            _NodeBody(node: node, controller: controller),
          ],
        ),
      ),
    );
  }
}

/// Header section of a node showing the label
class _NodeHeader extends StatelessWidget {
  final Node node;

  const _NodeHeader({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: NodeLayout.headerHeight,
      width: node.size.width,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: node.color,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
      ),
      child: Text(node.label, style: theme.textTheme.bodyLarge),
    );
  }
}

/// Body section containing connectors and node content
class _NodeBody extends StatelessWidget {
  final Node node;
  final NodeEditorController controller;

  const _NodeBody({required this.node, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          margin: EdgeInsets.only(top: NodeLayout.contentOffset, right: 5),
          width: NodeLayout.connectorSize,
          height: node.size.height,
          child: InputConnectorColumn(node: node, controller: controller),
        ),
        Expanded(child: node.build(context)),
        Container(
          margin: EdgeInsets.only(top: NodeLayout.contentOffset, left: 5),
          width: NodeLayout.connectorSize,
          height: node.size.height,
          child: OutputConnectorColumn(node: node, controller: controller),
        ),
      ],
    );
  }
}
