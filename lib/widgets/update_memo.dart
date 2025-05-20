import 'package:flutter/material.dart';

class MemoInputDialog extends StatefulWidget {
  const MemoInputDialog({super.key, this.initialValue});
  final String? initialValue;

  @override
  _MemoInputDialogState createState() => _MemoInputDialogState();
}

class _MemoInputDialogState extends State<MemoInputDialog> {
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Markup Text'),
      content: SizedBox(
        width: 3.0 *
            72, //MediaQuery.of(context).size.width * 4 / 10, // 4 inch wide assuming 10 inch screen width
        height: 1.5 *
            72, //MediaQuery.of(context).size.height * 1 / 10, // 1 inch high assuming 10 inch screen height
        child: TextField(
          controller: _controller,
          maxLines: null,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "",
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text("Update"),
          onPressed: () {
            Navigator.of(context).pop(_controller!.text);
          },
        ),
      ],
    );
  }
}

Future<String?> showUpdateMemoDialog(
    BuildContext context, String initialValue) {
  return showDialog(
    context: context,
    builder: (context) => MemoInputDialog(initialValue: initialValue),
  );
}
