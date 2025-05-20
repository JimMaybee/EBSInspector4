import 'package:flutter/material.dart';

Future<bool> alert({
  required BuildContext context,
  String? message,
  String title = "",
  String ok = "OK",
}) async {
  return (await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return AlertDialog(
                title: Text(title),
                content: Text(message!),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Text(ok),
                  ),
                ]);
          }))! ??
      false;
}
