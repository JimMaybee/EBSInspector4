import 'package:flutter/material.dart';

import '../Other/EBUtil.dart';

class Label extends StatelessWidget {
  const Label({super.key, required this.x, required this.y, required this.text, required this.style});
  final double? x;
  final double? y;
  final String? text;
  final Map<String, dynamic>? style;

  @override
  Widget build(BuildContext context) {
    var weight = FontWeight.normal;
    if (style!.containsKey("bold")) {
      // This above check shouldn't be required... Added to prevent crash.
      if (style!["bold"]) weight = FontWeight.bold;
    }
    final color = EBUtil.cvtColor(style!["fontcolor"], 1.0);
    var align = TextAlign.left;
    if (style!["align"].toLowerCase() == "center") align = TextAlign.center;
    if (style!["align"].toLowerCase() == "right") align = TextAlign.right;
    debugPrint("==== Align = ${style!["align"]}");

    Widget labelWidget;

    labelWidget = Text(text!,
        textAlign: align,
        style: TextStyle(
          fontSize: style!["fontsize"].toDouble(),
          fontWeight: weight,
          color: color,
          overflow: TextOverflow.ellipsis,
        ));

    return Padding(padding: EdgeInsets.only(left: x! * 72, top: y! * 72), child: labelWidget);
  }
}
