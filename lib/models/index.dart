import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Execution context that caches node results during a single execution run.
/// This prevents nodes from being executed multiple times when multiple
/// endpoint nodes (e.g., folder nodes) share the same upstream nodes.
class ExecutionContext {
  final Map<String, dynamic> _cache = {};
  final Set<String> _executing = {};

  /// Check if a node result is already cached
  bool hasCached(String uuid) => _cache.containsKey(uuid);

  /// Get cached result
  T? getCached<T>(String uuid) => _cache[uuid] as T?;

  /// Cache a result
  void cache(String uuid, dynamic result) {
    _cache[uuid] = result;
  }

  /// Mark node as currently executing (for cycle detection)
  /// Returns false if node is already executing (cycle detected)
  bool markExecuting(String uuid) {
    if (_executing.contains(uuid)) {
      return false; // Cycle detected
    }
    _executing.add(uuid);
    return true;
  }

  /// Mark node as done executing
  void markComplete(String uuid) {
    _executing.remove(uuid);
  }

  /// Clear all caches (for fresh run)
  void clear() {
    _cache.clear();
    _executing.clear();
  }
}

/// Represents a connection between two nodes
class Connection {
  Offset start;
  Offset end;
  Node startNode;
  int startIndex;
  Node? endNode;
  int? endIndex;

  Connection({
    required this.start,
    required this.end,
    required this.startNode,
    required this.startIndex,
    this.endIndex,
    this.endNode,
  });

  Map<String, dynamic> toJson() {
    return {
      "startNodeUuid": startNode.uuid,
      "startIndex": startIndex,
      "endNodeUuid": endNode?.uuid,
      "endIndex": endIndex,
      "start": {"dx": start.dx, "dy": start.dy},
      "end": {"dx": end.dx, "dy": end.dy},
    };
  }

  static Connection? fromJson(Map<String, dynamic> json, Map<String, Node> nodes) {
    final startNodeUuid = json["startNodeUuid"] as String;
    final endNodeUuid = json["endNodeUuid"] as String?;

    final startNode = nodes[startNodeUuid];
    if (startNode == null) return null;

    final endNode = endNodeUuid != null ? nodes[endNodeUuid] : null;

    return Connection(
      start: Offset((json["start"]["dx"] as num).toDouble(), (json["start"]["dy"] as num).toDouble()),
      end: Offset((json["end"]["dx"] as num).toDouble(), (json["end"]["dy"] as num).toDouble()),
      startNode: startNode,
      startIndex: json["startIndex"] as int,
      endNode: endNode,
      endIndex: json["endIndex"] as int?,
    );
  }
}

/// Data class holding common Node properties parsed from JSON
class NodeData {
  final String label;
  final Offset offset;
  final Size size;
  final Color color;
  final List<Input> inputs;
  final List<Output> outputs;
  final String? uuid;

  const NodeData({
    required this.label,
    required this.offset,
    required this.size,
    required this.color,
    required this.inputs,
    required this.outputs,
    this.uuid,
  });
}

/// Abstract base class for all node types in the editor
abstract class Node extends StatelessWidget {
  final String? id;
  final String label;
  final List<Input> inputs;
  final List<Output> outputs;
  final Color color;
  final String uuid;
  final Size size;
  Offset offset;

  /// Override this in subclasses with a string literal.
  /// Do not use runtimeType.toString() as it gets minified in release builds.
  String get typeName;

  Node({
    this.id,
    required this.label,
    required this.inputs,
    required this.outputs,
    this.offset = const Offset(0, 0),
    this.color = const Color.fromRGBO(128, 186, 215, 0.5),
    this.size = const Size(100, 100),
    String? uuid,
    super.key,
  }) : uuid = uuid ?? Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      "type": typeName,
      "uuid": uuid,
      "label": label,
      "offset": {"dx": offset.dx, "dy": offset.dy},
      "size": {"width": size.width, "height": size.height},
      "color": color.toARGB32(),
      "inputs": inputs.map((i) => i.toJson()).toList(),
      "outputs": outputs.map((o) => o.toJson()).toList(),
    };
  }

  /// Helper to parse all common Node properties from JSON
  /// Handles partial JSON with sensible defaults for missing fields
  static NodeData fromJson(Map<String, dynamic> json) {
    final offsetJson = json["offset"];
    final sizeJson = json["size"];
    final inputsJson = json["inputs"] as List<dynamic>?;
    final outputsJson = json["outputs"] as List<dynamic>?;

    return NodeData(
      uuid: json["uuid"] as String?,
      label: json["label"] as String? ?? "Node",
      offset: offsetJson != null
          ? Offset((offsetJson["dx"] as num).toDouble(), (offsetJson["dy"] as num).toDouble())
          : Offset.zero,
      size: sizeJson != null
          ? Size((sizeJson["width"] as num).toDouble(), (sizeJson["height"] as num).toDouble())
          : const Size(100, 100),
      color: json["color"] != null ? Color(json["color"] as int) : const Color.fromRGBO(128, 186, 215, 0.5),
      inputs: inputsJson?.map((i) => Input.fromJson(i)).toList() ?? [],
      outputs: outputsJson?.map((o) => Output.fromJson(o)).toList() ?? [],
    );
  }

  Future<void> init(BuildContext context) async {}

  /// Execute this node with caching support.
  /// Pass the ExecutionContext from the controller to enable caching.
  /// If this node's result is already cached, returns the cached result.
  /// Otherwise executes [run] and caches the result.
  Future<dynamic> execute(BuildContext context, ExecutionContext cache) async {
    // Return cached result if available
    if (cache.hasCached(uuid)) {
      return cache.getCached(uuid);
    }

    // Cycle detection
    if (!cache.markExecuting(uuid)) {
      throw Exception('Cycle detected at node: $label ($uuid)');
    }

    try {
      final result = await run(context, cache);
      cache.cache(uuid, result);
      return result;
    } finally {
      cache.markComplete(uuid);
    }
  }

  /// Override this method in subclasses to implement node-specific execution logic.
  Future<dynamic> run(BuildContext context, ExecutionContext cache) async {
    return Future.value();
  }

  @override
  Widget build(BuildContext context) => SizedBox();
}

/// Base class for node connectors (inputs and outputs)
abstract class Connector {
  final String label;
  final String? key;
  final Color color;
  final String uuid = "";

  const Connector({required this.label, this.key, required this.color});

  Map<String, dynamic> toJson() {
    return {"label": label, "key": key, "color": color.toARGB32()};
  }
}

/// Input connector for receiving data into a node
class Input extends Connector {
  const Input({required super.label, super.key, super.color = Colors.lightGreen});

  factory Input.fromJson(Map<String, dynamic> json) {
    return Input(label: json["label"], key: json["key"], color: Color(json["color"] as int));
  }
}

/// Output connector for sending data from a node
class Output extends Connector {
  const Output({required super.label, super.key, super.color = Colors.blue});

  factory Output.fromJson(Map<String, dynamic> json) {
    return Output(label: json["label"], key: json["key"], color: Color(json["color"] as int));
  }
}

/// Factory function type for creating nodes from JSON
typedef NodeFactory = Node Function(Map<String, dynamic> json);

/// Metadata for registered node types used in context menu and serialization
class NodeTypeMetadata {
  final String typeName;
  final String displayName;
  final String description;
  final IconData icon;
  final NodeFactory factory;

  NodeTypeMetadata({
    required this.typeName,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.factory,
  });
}
