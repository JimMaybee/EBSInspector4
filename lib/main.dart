// @formatter:off
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
///import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'EBClasses/Compiler/EBCompile.dart';
import 'EBClasses/Compiler/EBDictionary.dart';
import 'EBClasses/UI/EBExecute.dart';

Future<String> addNetworkInfoToSentry() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  String connectionType = 'unknown';

  // Check the result list for different connection types
  if (connectivityResult.contains(ConnectivityResult.wifi)) {
    connectionType = 'wifi';
  } else if (connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.ethernet)) {
    // Grouping mobile and ethernet under cellular for simplicity, adjust as needed
    connectionType = 'cellular';
  } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
    // Note: connectivity_plus doesn't guarantee detecting the underlying network type through a VPN.
    connectionType = 'vpn';
  } else if (connectivityResult.contains(ConnectivityResult.none)) {
    connectionType = 'none';
  }

  return connectionType;
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final dictionaryContents = await rootBundle.loadString("assets/dictionary.txt");
  await EBDictionary.compile(dictionaryContents);
  final templateSource = await rootBundle.loadString("assets/demo1Template.txt");
  //debugPrint(templateSource);
  await EBCompile.compile(templateSource);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var topMenu = false;
    if (kIsWeb) topMenu = true;
    if (defaultTargetPlatform == TargetPlatform.macOS) topMenu = true;

    EBExecute.init();
    //  EBForm.errorMessages = {};

    var ctls = <Widget>[];

    EBExecute.processFormDirectives(EBCompile.compiledTemplate["ProjectForm"]!);
    ctls += EBExecute.ctls;
    debugPrint("$ctls");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "EBS-Inspector 3.0",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Stack(
        children: ctls,
        //  Label(x: 1.0, y: 2.0, text: "Test Label 1", style: {"bold": true, "fontcolor": "Blue", "align": "Right", "url": "", "fontsize": 18.0}),
        // Label(x: 1.0, y: 4.0, text: "Test Label 2", style: {"bold": true, "fontcolor": "Red", "align": "Right", "url": "", "fontsize": 14.0}),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      navigatorObservers: [SentryNavigatorObserver()],
    );
  }
}

class FailToLaunch extends StatelessWidget {
  const FailToLaunch({super.key, this.msg});
  final String? msg;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "EBS3",
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(body: Center(child: Text("Unable to launch EBS-Inspector 3.0.\n$msg"))));
  }
}
