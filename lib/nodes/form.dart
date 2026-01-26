import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/index.dart';

enum FormInputType { text, textArea, range, int, double, dropdown }

FilteringTextInputFormatter _doubleInputFilter = FilteringTextInputFormatter.allow(RegExp(r'(^\d*[\.]?\d{0,2})'));

typedef Validator = String? Function(String?)?;
typedef Suffix = Widget Function(BuildContext);
typedef OnChange = void Function(String value);

class FormInput {
  String label;
  int min;
  int max;
  double width;
  double height;
  FormInputType type;
  TextEditingController controller = TextEditingController();
  String? defaultValue;
  Validator? validator;
  List<String>? options;
  Suffix? suffix;
  OnChange? callback;
  int maxLines;
  int minLines;
  FormInput({
    required this.label,
    required this.type,
    this.min = 64,
    this.max = 1024,
    this.width = 100,
    this.height = 60,
    this.maxLines = 1,
    this.minLines = 1,
    this.defaultValue,
    this.validator,
    this.options,
    this.suffix,
    this.callback,
  }) {
    if (defaultValue != null) controller = TextEditingController(text: defaultValue);
  }

  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colors = theme.colorScheme;

    InputDecoration inputDecoration(String labelText) => InputDecoration(
      labelText: labelText,
      labelStyle: theme.textTheme.bodySmall?.copyWith(color: colors.tertiary),
      floatingLabelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.highlightColor),
      filled: true,
      fillColor: theme.canvasColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.shadow),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.shadow),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.highlightColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
    );

    Widget buildContainer({required Widget child}) =>
        Container(width: width, height: height, padding: const EdgeInsets.all(4), child: child);

    switch (type) {
      case .textArea || .text:
        return buildContainer(
          child: TextFormField(
            controller: controller,
            style: theme.textTheme.bodyMedium,
            decoration: inputDecoration(label),
            minLines: minLines,
            maxLines: maxLines,
            keyboardType: type == .text ? TextInputType.text : TextInputType.multiline,
            validator: validator,
          ),
        );

      case .int || .double:
        return buildContainer(
          child: TextFormField(
            inputFormatters: [type == .double ? _doubleInputFilter : FilteringTextInputFormatter.digitsOnly],
            controller: controller,
            style: theme.textTheme.bodyMedium,
            decoration: inputDecoration(label),
            keyboardType: TextInputType.number,
            validator: validator,
            onChanged: callback,
          ),
        );

      case .range:
        return buildContainer(
          child: TextFormField(
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            controller: controller,
            style: theme.textTheme.bodyMedium,
            decoration: inputDecoration(label),
            keyboardType: TextInputType.number,
            validator: validator,
            onChanged: callback,
          ),
        );

      case .dropdown:
        assert(options != null, "When using dropdown, options field must be attached");
        return buildContainer(
          child: DropdownButtonFormField<String>(
            initialValue: defaultValue,
            style: theme.textTheme.bodyMedium,
            dropdownColor: colors.primary,
            decoration: inputDecoration(label),
            icon: Icon(Icons.keyboard_arrow_down, color: colors.tertiary),
            items: options!
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: SizedBox(
                      width: width - 64,
                      child: Text(item, style: theme.textTheme.bodyMedium, overflow: .clip),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              defaultValue = value.toString();
              controller.text = value.toString();
              if (callback != null) callback!(value.toString());
            },
          ),
        );
    }
  }

  factory FormInput.fromJson(Map<String, dynamic> json) {
    final input = FormInput(
      label: json["label"],
      type: FormInputType.values.byName(json["type"]),
      min: json["min"] ?? 64,
      max: json["max"] ?? 1024,
      width: (json["width"] as num?)?.toDouble() ?? 100,
      height: (json["height"] as num?)?.toDouble() ?? 60,
      maxLines: json["maxLines"] ?? 1,
      minLines: json["minLines"] ?? 1,
      defaultValue: json["defaultValue"],
      options: (json["options"] as List<dynamic>?)?.cast<String>(),
    );

    // Restore the saved value
    if (json["value"] != null) {
      input.controller.text = json["value"] as String;
    }

    return input;
  }

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "type": type.name,
      "min": min,
      "max": max,
      "width": width,
      "height": height,
      "maxLines": maxLines,
      "minLines": minLines,
      "defaultValue": defaultValue,
      "value": controller.text,
      "options": options,
    };
  }
}

Validator defaultValidator = (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a prompt';
  }
  return null;
};

class FormNode extends Node {
  @override
  String get typeName => 'FormNode';

  FormNode({
    super.color = Colors.orangeAccent,
    super.backgroundColor,
    super.label = "Default form",
    super.size = const Size(500, 500),
    super.inputs = const [],
    super.outputs = const [],
    super.offset,
    super.uuid,
    super.key,
    this.formInputs = const [],
  });

  List<FormInput> formInputs;
  final formKey = GlobalKey<FormState>();

  factory FormNode.fromJson(Map<String, dynamic> json) {
    final data = Node.fromJson(json);
    final formInputs = (json["formInputs"] as List<dynamic>?)?.map((i) => FormInput.fromJson(i)).toList() ?? [];

    return FormNode(
      label: data.label,
      offset: data.offset,
      size: data.size,
      color: data.color,
      inputs: data.inputs,
      outputs: data.outputs,
      uuid: json["uuid"] as String?,
      formInputs: formInputs,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json["formInputs"] = formInputs.map((i) => i.toJson()).toList();
    return json;
  }

  @override
  Future<dynamic> run(BuildContext context, ExecutionContext cache) async {
    throw Exception("Form execution failed");
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: size.width, maxHeight: size.height),
        child: Wrap(
          spacing: 5,
          runSpacing: 8,
          children: formInputs
              .map(
                (item) => Row(
                  crossAxisAlignment: .start,
                  mainAxisAlignment: .start,
                  mainAxisSize: .min,
                  spacing: 5,
                  children: [item.build(context), if (item.suffix != null) item.suffix!(context)],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
