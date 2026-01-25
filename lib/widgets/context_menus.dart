import 'package:flutter/material.dart';
import '../models/index.dart';
import '../controller/node_editor_controller.dart';

/// Item definition for node context menu
class ContextMenuItem {
  final String name;
  final String value;
  final IconData icon;
  final int size;

  const ContextMenuItem({required this.name, required this.value, required this.icon, this.size = 20});
}

/// Default menu items for node context menu
const List<ContextMenuItem> defaultNodeMenuItems = [
  ContextMenuItem(name: "Delete", value: "delete", icon: Icons.delete),
  ContextMenuItem(name: "Disconnect connections", value: "disconnect", icon: Icons.clear),
];

/// Utility class for showing context menus in the node editor
class NodeEditorContextMenus {
  /// Shows context menu when right-clicking on a node
  static void showNodeMenu({
    required BuildContext context,
    required Offset globalPosition,
    required Node node,
    required NodeEditorController controller,
    List<ContextMenuItem> menuItems = defaultNodeMenuItems,
  }) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final ThemeData theme = Theme.of(context);

    showMenu<String>(
      context: context,
      color: theme.colorScheme.secondary,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: menuItems
          .map(
            (item) => PopupMenuItem(
              value: item.value,
              child: Row(
                spacing: 8,
                children: [
                  Icon(item.icon, size: 20, color: theme.colorScheme.onSurface),
                  Text(item.name),
                ],
              ),
            ),
          )
          .toList(),
    ).then((value) {
      switch (value) {
        case 'delete':
          controller.removeNode(node.uuid);
          break;
        case 'disconnect':
          controller.disconnectNode(node.uuid);
          break;
      }
    });
  }

  /// Shows context menu when right-clicking on empty canvas space
  static void showCanvasMenu({
    required BuildContext context,
    required Offset localPosition,
    required Offset canvasPosition,
    required NodeEditorController controller,
    required void Function(String typeName, Offset position) onNodeCreate,
  }) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final ThemeData theme = Theme.of(context);
    final registeredNodes = controller.registeredNodeTypes;

    if (registeredNodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No node types registered. Use registerNodeType() to register nodes.')),
      );
      return;
    }

    showMenu<String>(
      context: context,
      color: theme.colorScheme.secondary,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(localPosition.dx, localPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: registeredNodes.map((metadata) => _buildNodeTypeMenuItem(metadata, theme)).toList(),
    ).then((typeName) {
      if (typeName != null) {
        onNodeCreate(typeName, canvasPosition);
      }
    });
  }

  static PopupMenuItem<String> _buildNodeTypeMenuItem(NodeTypeMetadata metadata, ThemeData theme) {
    return PopupMenuItem(
      value: metadata.typeName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(metadata.icon, size: 20, color: theme.colorScheme.onSurface),
              Text(metadata.displayName, style: theme.textTheme.bodyMedium),
            ],
          ),
          if (metadata.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                metadata.description,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
        ],
      ),
    );
  }
}
