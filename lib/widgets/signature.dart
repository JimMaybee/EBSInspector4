import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';

final _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class Signature extends StatefulWidget {
  const Signature._({
    required this.width,
    required this.height,
  });

  static Future<Uint8List?> show(BuildContext context,
      {Widget? title,
      int width = 864, // 12"
      int height = 216 // 3"
      }) async {
    final computedTitle = title ?? const Text('Signature');
    if (_isMobile) {
      return Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                title: computedTitle,
              ),
              body: Center(
                child: Signature._(
                  width: width,
                  height: height,
                ),
              ),
            );
          },
        ),
      );
    }

    return await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: computedTitle,
          content: Signature._(
            width: width,
            height: height,
          ),
        );
      },
    );
  }

  final int width;
  final int height;

  @override
  State<Signature> createState() => SignatureState();
}

class SignatureState extends State<Signature> {
  var _hasPath = false;

  final _control = HandSignatureControl(
    threshold: 0.001,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );

  void _pathUpdated() {
    setState(() {
      _hasPath = _control.paths.isNotEmpty;
    });
  }

  @override
  void initState() {
    _control.addListener(_pathUpdated);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _control.removeListener(_pathUpdated);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints.expand(
              width: widget.width.toDouble(),
              height: widget.height.toDouble(),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor),
                color: Colors.white,
              ),
              child: HandSignature(
                  control: _control, type: SignatureDrawType.shape),
            ),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close)),
              IconButton(
                  onPressed: _hasPath ? _control.stepBack : null,
                  icon: const Icon(Icons.undo)),
              IconButton(
                  onPressed: _hasPath
                      ? () async {
                          final nav = Navigator.of(context);
                          final signature = (await _control.toImage(
                            width: widget.width,
                            height: widget.height,
                            border: 10,
                          ))!;
                          nav.pop<Uint8List>(signature.buffer.asUint8List());
                        }
                      : null,
                  icon: const Icon(Icons.check)),
            ],
          ),
        ],
      ),
    );
  }
}
