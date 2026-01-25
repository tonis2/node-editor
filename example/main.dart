import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:node_editor/index.dart';
import 'package:flutter/services.dart' show rootBundle, LogicalKeyboardKey;
import 'node.dart';

class NodeEditor extends StatefulWidget {
  const NodeEditor({super.key});

  @override
  State<NodeEditor> createState() => _State();
}

class _State extends State<NodeEditor> {
  bool loading = false;
  NodeEditorController nodeController = NodeEditorController();

  @override
  void initState() {
    nodeController.registerNodeType(
      NodeTypeMetadata(
        typeName: 'ImageNode',
        displayName: 'Image',
        description: 'Load and display images',
        icon: Icons.image,
        factory: (json) => ImageNode.fromJson(json),
      ),
    );

    nodeController.registerNodeType(
      NodeTypeMetadata(
        typeName: 'FolderNode',
        displayName: 'Folder',
        description: 'Create folder for images',
        icon: Icons.edit_note,
        factory: (json) => FolderNode.fromJson(json),
      ),
    );
    super.initState();
  }

  Future<void> saveCanvas({bool saveAsFile = false}) async {
    // Save canvas as json, for example to file or localstorage
    var data = jsonEncode(nodeController.toJson());
    print(data.toString());
  }

  Future<void> loadConfig() async {
    // Load nodes to canvas from json
    nodeController.fromJson(jsonDecode("{node: 'data'}"), context);
  }

  @override
  Widget build(BuildContext context) {
    // This tree looks kind of ugly, but it should pretty much remain the same if you use it, if you want to have all functionalities for the canvas.
    // You need to be able to query NodeEditorController? editor = NodeControls.of(context); from your custom nodes.
    // You want to be able to have keybindings probably
    // Having builder for ctx is also neccesary, otherwise executeAllEndpoints wont work, cause it has no NodeEditorController
    return NodeControls(
      notifier: nodeController,
      child: CallbackShortcuts(
        bindings: {SingleActivator(LogicalKeyboardKey.keyS, control: true): saveCanvas},
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: NodeCanvas(controller: nodeController, zoom: 0.5),
            floatingActionButton: Builder(
              builder: (ctx) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 10,
                  children: [
                    FloatingActionButton(
                      heroTag: "run",
                      onPressed: () => nodeController.executeAllEndpoints(ctx),
                      child: Icon(Icons.play_arrow),
                    ),
                    FloatingActionButton(
                      heroTag: "save",
                      onPressed: () => saveCanvas(saveAsFile: true),
                      child: Icon(Icons.save),
                    ),
                    FloatingActionButton(heroTag: "load", onPressed: loadConfig, child: Icon(Icons.folder_open)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
