import 'package:easy_nodes/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _formNode(String uuid, double dx, double dy) => {
  'type': 'FormNode',
  'uuid': uuid,
  'label': uuid,
  'offset': {'dx': dx, 'dy': dy},
  'size': {'width': 240.0, 'height': 280.0},
  'color': 0xFF000000,
  'inputs': <dynamic>[],
  'outputs': <dynamic>[],
  'formInputs': <dynamic>[],
};

NodeEditorController _controllerWithFormNode() {
  final controller = NodeEditorController();
  controller.registerNodeType(
    NodeTypeMetadata(
      typeName: 'FormNode',
      displayName: 'Form',
      description: '',
      icon: Icons.list,
      factory: (json) => FormNode.fromJson(json),
    ),
  );
  return controller;
}

void main() {
  testWidgets('fromJson shifts off-canvas (negative) offsets back on-canvas',
      (tester) async {
    final controller = _controllerWithFormNode();

    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );

    await controller.fromJson({
      'nodes': [
        _formNode('a', -206.8, 10.0), // off-canvas to the left
        _formNode('b', 500.0, 400.0),
      ],
      'connections': <dynamic>[],
    }, ctx);

    // minX = -206.8 -> shift +246.8 to reach the 40px margin; minY = 10 -> +30.
    final a = controller.nodes['a']!;
    final b = controller.nodes['b']!;
    expect(a.offset.dx, closeTo(40.0, 0.01));
    expect(a.offset.dy, closeTo(40.0, 0.01));
    expect(b.offset.dx, closeTo(746.8, 0.01));
    expect(b.offset.dy, closeTo(430.0, 0.01));
  });

  testWidgets('fromJson leaves already-on-canvas graphs unchanged',
      (tester) async {
    final controller = _controllerWithFormNode();

    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );

    await controller.fromJson({
      'nodes': [_formNode('a', 100.0, 80.0)],
      'connections': <dynamic>[],
    }, ctx);

    expect(controller.nodes['a']!.offset, const Offset(100.0, 80.0));
  });
}
