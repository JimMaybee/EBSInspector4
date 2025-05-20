import 'dart:async';
import 'package:flutter/material.dart';

Future<T> progress<T>({
  required BuildContext context,
  Future<T>? result,
  Stream<double>? value,
  Stream<Widget>? message,
  Widget? title,
}) async {
  BuildContext? innerContext;

  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      innerContext = context;
      return AlertDialog(
        title: title,
        content: SingleChildScrollView(
          child: _ProgressIndicator(value, message),
        ),
      );
    },
  ));

  try {
    return (await result) as T;
  } finally {
    if (innerContext != null) {
      Navigator.pop(innerContext!);
    }
  }
}

class _ProgressIndicator extends StatefulWidget {
  const _ProgressIndicator(this.value, this.message);
  final Stream<double>? value;
  final Stream<Widget>? message;

  @override
  State<_ProgressIndicator> createState() => _ProgressIndicatorState();
}

class _ProgressIndicatorState extends State<_ProgressIndicator> {
  StreamSubscription<double>? _sub;
  StreamSubscription<Widget>? _subMessage;
  double? _value;
  Widget? _message;

  @override
  void initState() {
    _sub = widget.value?.listen((event) {
      if (mounted) {
        setState(() {
          _value = event;
        });
      }
    });
    _subMessage = widget.message?.listen((event) {
      if (mounted) {
        setState(() {
          _message = event;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _subMessage?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListBody(
      children: <Widget>[
        LinearProgressIndicator(value: _value),
        const SizedBox(height: 16),
        if (_message != null) Center(child: _message),
      ],
    );
  }
}
