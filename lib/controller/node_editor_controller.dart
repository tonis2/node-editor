import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../utils/node_layout.dart';

/// InheritedWidget that provides NodeEditorController to descendants
class NodeControls extends InheritedNotifier<NodeEditorController> {
  const NodeControls({required super.child, required super.notifier, super.key});

  static NodeEditorController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NodeControls>()?.notifier;

  @override
  bool updateShouldNotify(InheritedNotifier<NodeEditorController> oldWidget) => true;
}

/// Controller for managing node editor state
class NodeEditorController extends ChangeNotifier {
  final Map<String, Node> nodes = HashMap();
  List<Connection> connections = [];
  Connection? activeConnection;
  final List<ExecutionContext> _executionContexts = [];

  /// Get all active execution contexts
  List<ExecutionContext> get executionContexts => List.unmodifiable(_executionContexts);

  /// Check if any execution is in progress
  bool get isExecuting => _executionContexts.isNotEmpty;

  /// Registry with metadata for context menu display
  final Map<String, NodeTypeMetadata> _nodeRegistry = {};

  NodeEditorController();

  /// Unified registration method with metadata
  void registerNodeType(NodeTypeMetadata metadata) {
    _nodeRegistry[metadata.typeName] = metadata;
    notifyListeners();
  }

  /// Get all registered node types for context menu
  List<NodeTypeMetadata> get registeredNodeTypes => _nodeRegistry.values.toList();

  /// Get metadata for a specific node type
  NodeTypeMetadata? getNodeMetadata(String typeName) {
    return _nodeRegistry[typeName];
  }

  /// Convert the entire canvas state to JSON
  Map<String, dynamic> toJson() {
    return {
      "nodes": nodes.values.map((node) => node.toJson()).toList(),
      "connections": connections.map((conn) => conn.toJson()).toList(),
    };
  }

  /// Restore canvas state from JSON
  Future<void> fromJson(Map<String, dynamic> json, BuildContext context) async {
    nodes.clear();
    connections.clear();

    // First pass: create all nodes
    final nodeList = json["nodes"] as List<dynamic>;
    for (final nodeJson in nodeList) {
      final typeName = nodeJson["type"] as String;
      final nodeData = _nodeRegistry[typeName];

      if (nodeData == null) {
        throw Exception("Unknown node type: $typeName. Register it with registerNodeType()");
      }

      final node = nodeData.factory(nodeJson);

      await node.init(context);
      nodes[node.uuid] = node;
    }

    // Second pass: restore connections
    final connList = json["connections"] as List<dynamic>;
    for (final connJson in connList) {
      final connection = Connection.fromJson(connJson, nodes);
      if (connection != null) {
        connections.add(connection);
      }
    }

    notifyListeners();
  }

  /// Clear all nodes and connections
  void clear() {
    nodes.clear();
    connections.clear();
    activeConnection = null;
    notifyListeners();
  }

  void requestUpdate() {
    notifyListeners();
  }

  void setActiveConnection(Connection connection) {
    activeConnection = connection;
    notifyListeners();
  }

  void addConnection(Connection connection) {
    connections.add(connection);
    activeConnection = null;
    notifyListeners();
  }

  void removeConnection(Connection connection) {
    connections.remove(connection);
    activeConnection = null;
    notifyListeners();
  }

  void removeActive() {
    if (activeConnection != null) {
      activeConnection = null;
      notifyListeners();
    }
  }

  void setNodePosition(Offset offset, Node node) {
    activeConnection = null;
    node.offset = offset;

    var previousConnections = connections.where(
      (conn) => conn.startNode.uuid == node.uuid || conn.endNode?.uuid == node.uuid,
    );

    if (previousConnections.isNotEmpty) {
      for (var conn in previousConnections) {
        if (conn.startNode.uuid == node.uuid) {
          conn.start = NodeLayout.outputConnectorPosition(node, conn.startIndex);
        } else if (conn.endNode?.uuid == node.uuid && conn.endNode != null) {
          conn.end = NodeLayout.inputConnectorPosition(node, conn.endIndex!);
        }
      }
    }
    notifyListeners();
  }

  void connectNodes(Node startNode, Node endNode, int startIndex, int endIndex) {}

  /// Return connected nodes for the node at output index
  List<Node> outGoingNodes(Node node, int index) {
    List<Node> result = [];
    for (var conn in connections) {
      if (conn.startNode.uuid == node.uuid && conn.startIndex == index && conn.endNode != null) {
        result.add(conn.endNode!);
      }
    }
    return result;
  }

  /// Return nodes connected to input at index
  List<Node> incomingNodes(Node node, int index) {
    List<Node> result = [];
    for (var conn in connections) {
      if (conn.endNode?.uuid == node.uuid && conn.endIndex == index) {
        result.add(conn.startNode);
      }
    }
    return result;
  }

  /// Find node at the given canvas position
  Node? findNodeAtPosition(Offset position) {
    for (var entry in nodes.entries) {
      final node = entry.value;
      final rect = NodeLayout.nodeRect(node);
      if (rect.contains(position)) {
        return node;
      }
    }
    return null;
  }

  void addNodes(List<Node> items) {
    for (var node in items) {
      nodes[node.uuid] = node;
    }
    notifyListeners();
  }

  void addNode(Node node, Offset? position) {
    nodes[node.uuid] = node;
    if (position != null) setNodePosition(position, node);
    notifyListeners();
  }

  /// Remove a node and all its connections
  void removeNode(String uuid) {
    nodes.remove(uuid);
    connections.removeWhere((conn) => conn.startNode.uuid == uuid || conn.endNode?.uuid == uuid);
    notifyListeners();
  }

  /// Disconnect all connections from a node
  void disconnectNode(String uuid) {
    connections.removeWhere((conn) => conn.startNode.uuid == uuid || conn.endNode?.uuid == uuid);
    notifyListeners();
  }

  /// Find all endpoint nodes (nodes with no outgoing connections)
  List<Node> getEndpointNodes() {
    return nodes.values.where((node) {
      // A node is an endpoint if none of its outputs are connected
      return !connections.any((conn) => conn.startNode.uuid == node.uuid);
    }).toList();
  }

  /// Execute all endpoint nodes with a shared ExecutionContext.
  /// This ensures upstream nodes are only executed once, even when
  /// multiple endpoints depend on them.
  /// Multiple executions can run concurrently, each with its own context.
  Future<void> executeAllEndpoints(BuildContext context) async {
    assert(NodeControls.of(context) != null);

    final cache = ExecutionContext();
    _executionContexts.add(cache);
    notifyListeners();

    try {
      final endpoints = getEndpointNodes();

      for (final endpoint in endpoints) {
        try {
          await endpoint.execute(context, cache);
        } catch (e) {
          debugPrint('Error executing endpoint ${endpoint.label}: $e');
        }
      }
    } finally {
      _executionContexts.remove(cache);
      notifyListeners();
    }
  }

  /// Execute specific endpoint nodes with a shared ExecutionContext.
  /// Multiple executions can run concurrently, each with its own context.
  Future<void> executeEndpoints(BuildContext context, List<Node> endpoints) async {
    assert(NodeControls.of(context) != null);

    final executionCache = ExecutionContext();
    _executionContexts.add(executionCache);
    notifyListeners();

    try {
      for (final endpoint in endpoints) {
        try {
          await endpoint.execute(context, executionCache);
        } catch (e) {
          debugPrint('Error executing endpoint ${endpoint.label}: $e');
        }
      }
    } finally {
      _executionContexts.remove(executionCache);
      notifyListeners();
    }
  }
}
