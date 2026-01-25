# Node Editor

A Flutter library for creating visual node-based editors with draggable, connectable nodes on an interactive canvas.

## Features

- **Interactive Canvas** - Pan, zoom, and drag nodes on a GPU-accelerated grid background
- **Connectable Nodes** - Create connections between node inputs and outputs with Bezier curves
- **Execution Pipeline** - Execute node graphs with automatic dependency resolution and caching
- **Cycle Detection** - Prevents infinite loops during execution
- **Serialization** - Save and load entire canvas state to/from JSON
- **Context Menus** - Right-click to create nodes or manage existing ones
- **Extensible** - Easy to create custom node types

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  node_editor:
    git:
      url: git@github.com:tonis2/node-editor.git
      ref: main
```

## Quick Start

### 1. Create a Controller

```dart
import 'package:node_editor/index.dart';

final controller = NodeEditorController();
```

### 2. Register Node Types

```dart
controller.registerNodeType(
  NodeTypeMetadata(
    typeName: 'MyNode',
    displayName: 'My Node',
    description: 'A custom node',
    icon: Icons.widgets,
    factory: (json) => MyNode.fromJson(json),
  ),
);
```

### 3. Add the Canvas Widget

```dart
NodeControls(
  notifier: controller,
  child: Scaffold(
    body: NodeCanvas(controller: controller, zoom: 0.5),
    floatingActionButton: FloatingActionButton(
      onPressed: () => controller.executeAllEndpoints(context),
      child: Icon(Icons.play_arrow),
    ),
  ),
)
```

## Creating Custom Nodes

Extend the `Node` class to create custom nodes:

```dart
class MyNode extends Node {
  @override
  String get typeName => 'MyNode';

  MyNode({
    super.label = 'My Node',
    super.offset = Offset.zero,
    super.inputs = const [Input(label: 'In')],
    super.outputs = const [Output(label: 'Out')],
  });

  @override
  Widget build(BuildContext context) {
    return Text('Node content');
  }

  @override
  Future<dynamic> run(BuildContext context, ExecutionContext cache) async {
    // Get data from connected input nodes
    final editor = NodeControls.of(context);
    final incoming = editor.incomingNodes(this, 0);

    for (var node in incoming) {
      var data = await node.execute(context, cache);
      // Process data...
    }

    return result;
  }

  // Serialization
  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    // Add custom fields
  };

  factory MyNode.fromJson(Map<String, dynamic> json) {
    return MyNode(
      label: json['label'],
      offset: Offset(json['offset']['dx'], json['offset']['dy']),
    )..uuid = json['uuid'];
  }
}
```

## API Reference

### NodeEditorController

The main controller for managing canvas state.

| Method | Description |
|--------|-------------|
| `addNode(node, offset?)` | Add a node to the canvas |
| `removeNode(uuid)` | Remove a node and its connections |
| `setNodePosition(offset, node)` | Move a node |
| `addConnection(connection)` | Create a connection between nodes |
| `removeConnection(connection)` | Remove a connection |
| `incomingNodes(node, inputIndex)` | Get nodes connected to an input |
| `outGoingNodes(node, outputIndex)` | Get nodes connected to an output |
| `executeAllEndpoints(context)` | Execute all endpoint nodes |
| `toJson()` / `fromJson(json)` | Serialize/deserialize canvas |

### Node

Base class for all nodes.

| Property | Description |
|----------|-------------|
| `uuid` | Unique identifier |
| `label` | Display name |
| `offset` | Position on canvas |
| `size` | Node dimensions |
| `inputs` | List of input connectors |
| `outputs` | List of output connectors |

| Method | Description |
|--------|-------------|
| `build(context)` | Override to render custom content |
| `run(context, cache)` | Override to implement execution logic |
| `init(context)` | Optional async initialization |
| `toJson()` / `fromJson()` | Serialization |

### Input / Output

Connectors for node connections.

```dart
Input(label: 'Data', color: Colors.green)
Output(label: 'Result', color: Colors.blue)
```

## Controls

- **Left-click + drag** - Move nodes
- **Middle-click + drag** - Pan canvas
- **Scroll wheel** - Zoom in/out
- **Right-click canvas** - Open node creation menu
- **Right-click node** - Open node context menu (delete, disconnect)
- **Click output → Click input** - Create connection

## License

MIT
