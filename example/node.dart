import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:node_editor/index.dart';

List<FormInput> _defaultNodes = [
  FormInput(
    label: "Folders",
    type: FormInputType.dropdown,
    width: 300,
    height: 80,
    validator: defaultValidator,
    options: ["Images", "Text"],
  ),
];

class NewData {
  List<int> data;
  String name;
  NewData({required this.data, required this.name});
}

// Creating custom node, you can extend previous node like FormNode or just Node
class FolderNode extends FormNode {
  @override
  String get typeName => 'FolderNode';

  FolderNode({
    super.color = Colors.lightGreen,
    super.label = "Folder",
    super.size = const Size(400, 200),
    super.inputs = const [Input(label: "Result", color: Colors.yellow)],
    super.outputs = const [],
    super.offset,
    super.uuid,
    super.key,
    List<FormInput>? customFormInputs,
  }) : super(formInputs: customFormInputs ?? []);

  factory FolderNode.fromJson(Map<String, dynamic> json) {
    // Load node data and form inputs from json and then create a new node from that data.
    // Used when loading node canvas from json storage for example

    final data = Node.fromJson(json);
    final formInputs =
        (json["formInputs"] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList() ?? _defaultNodes;

    return FolderNode(
      label: "Folder",
      size: const Size(400, 200),
      color: Colors.lightGreen,
      inputs: const [Input(label: "Image", color: Colors.yellow)],
      outputs: const [],
      uuid: data.uuid,
      offset: data.offset,
      customFormInputs: formInputs,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    formInputs[0].options = [];
    return super.toJson();
  }

  @override
  Future<void> init(BuildContext context) async {
    // In here you can load some dynamic data, for example a form that shows data coming from server
    return super.init(context);
  }

  @override
  Future<dynamic> run(BuildContext context, ExecutionContext cache) async {
    NodeEditorController? editor = NodeControls.of(context);

    // Get a list of all connected nodes at input index 0, in here you can gather all data coming to an input.
    // You can do the same loop for every input running into the node.

    List<Node>? incomingNodes = editor?.incomingNodes(this, 0) ?? [];
    for (var node in incomingNodes) {
      var image = await node.execute(context, cache);
      // After the connected data is recieved, you can edit it, change it ..etc.
      // Then you store in in the class and when next node calls this node, you can return it.
    }

    // Update the canvas, this way you could change active node colors ..etc
    editor?.requestUpdate();

    // Returns new data for the next node in line.
    return NewData(data: [1231], name: "test");
  }
}

// Image loading node
class ImageNode extends Node {
  @override
  String get typeName => 'ImageNode';

  ImageNode({
    super.color = Colors.lightGreen,
    super.label = "Image",
    super.size = const Size(400, 400),
    super.inputs = const [],
    super.outputs = const [Output(label: "Image", color: Colors.yellow), Output(label: "Mask")],
    super.offset,
    super.uuid,
    super.key,
    this.data = const [],
  });

  factory ImageNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    return ImageNode(
      label: "Image",
      size: const Size(400, 400),
      color: Colors.lightGreen,
      inputs: const [],
      outputs: const [
        Output(label: "Image", color: Colors.yellow),
        Output(label: "Mask"),
      ],
      offset: data.offset,
      uuid: data.uuid,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return super.toJson();
  }

  List<int> data = [];

  @override
  Future<List<int>> run(BuildContext context, ExecutionContext cache) async {
    if (data.isEmpty) throw Exception("Image is empty");

    // Do some image editing here ?

    return data;
  }

  void pickImage(BuildContext context) async {
    // Use file loader to pick image
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    NodeEditorController? provider = NodeControls.of(context);

    return Column(
      children: [
        InkWell(
          onTap: () => pickImage(context),
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(color: Colors.grey),
            child: Stack(
              children: [
                if (data.isEmpty)
                  Positioned(left: 75, top: 120, child: Text("Click to pick image", style: theme.textTheme.bodyLarge)),
                if (data.isNotEmpty) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 300,
                    height: 300,
                    child: Image(image: MemoryImage(Uint8List.fromList(data)), width: 300, height: 300, fit: .cover),
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: InkWell(
                      child: Icon(Icons.delete, color: Colors.redAccent),
                      onTap: () {
                        data = [];
                        // Update the canvas after clearing image
                        provider?.requestUpdate();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
