import 'dart:async';

import 'package:flutter/material.dart';

Future<bool> confirm({
  required BuildContext context,
  String? message,
  String title = "",
}) async {
  final actions = <Widget>[];
  actions.add(TextButton(
      onPressed: () {
        Navigator.of(context).pop(false);
      },
      child: Text("NO")));

  actions.add(TextButton(
      onPressed: () {
        Navigator.of(context).pop(true);
      },
      child: Text("YES")));

  return (await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
                title: Text(title), content: Text(message!), actions: actions);
          }))! ??
      false;
}

Future<String> confirmWithAll({
  required BuildContext context,
  String? message,
  String title = "",
}) async {
  final actions = <Widget>[];
  actions.add(TextButton(
      onPressed: () {
        Navigator.of(context).pop("No");
      },
      child: Text("NO")));

  actions.add(TextButton(
      onPressed: () {
        Navigator.of(context).pop("Yes");
      },
      child: Text("YES")));

  actions.add(TextButton(
    onPressed: () {
      Navigator.of(context).pop("All");
    },
    child: Text("ALL"),
  ));

  return (await showDialog<String>(
          context: context,
          builder: (context) {
            return AlertDialog(
                title: Text(title), content: Text(message!), actions: actions);
          })) ??
      false as FutureOr<String>;
}
