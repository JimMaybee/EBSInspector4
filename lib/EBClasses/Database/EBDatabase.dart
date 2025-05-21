// // @formatter:off

// import 'dart:core';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:firebase_core/firebase_core.dart' as firebase_core;
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:validators/validators.dart';

// import '../../extensions.dart';
// import '../../firebase_options.dart';
// //import '../../widgets/progress.dart';
// import '../Compiler/EBCompile.dart';
// import '../Compiler/EBTypes.dart';
// import '../Database/EBCollection.dart';
// ///import '../Offline/EBSqfLite.dart';
// ///import '../Other/EBAppController.dart';
// ///import '../Other/EBReport.dart';
// import '../Other/EBUtil.dart';
// ///import '../UI/EBAppMenu2.dart';
// import '../UI/EBForm.dart';
// ///import 'EBAuth.dart';
// ///import 'EBDatabaseScripts.dart';

// class EBDatabase {
//   // PROPERTIES:
//   // -----------

//   //static String databaseMode = "Demo";
//   static bool online = true;
//   static bool firestoreAuthenticated = false;
//   ///static EBSqfLite sqfLite = EBSqfLite();
//   //static String databaseName = "";
//   static bool testMode = false; // Sequential primary keys are generated in testMode (versus 10 character random keys)
//   static List<String>? collectionNames; // NOT IMPLEMENTED. Used by EBCompile to validate collection references - before collections has been set.
//   static Map<String, List<String>>? fieldNames; // NOT IMPLEMENTED. Used by EBCompile to validate field names.
//   static Map<String, EBCollection> collections = {};
//   static Map<String, EBCollection?> collectionsByReference = {};
//   static List<String> collectionList = [];

//   static Map<String, String?> defineVars = {
//     "#Year#": "${DateTime.now().year}",
//     "#test#": "1",
//     "#RunningTest#": "No",
//     "#ShortName#": ""
//   }; // Can be double, i.e. pageNumber
//   static Map<String, String?> defineMemos = {};
//   static String defaultCollectionName = ""; // This is used in EBList to allow field reference without the collection name. Bad design... To be removed.
//   static bool processingMergeExpression = false;
//   static String useCollection = "";
//   static late EBCollection dbCollection;
//   static String dbFields = "";
//   static bool trace = false;
//   static List<String> stackVals = [];
//   static String deviceDocuments = "";
//   static Map<String, Uint8List?> preloadedImages = {};
//   static late CollectionReference<EBDirective> fsTransactions;
//   static SharedPreferences? pref;
//   static Map<String, String?> templatesForIncludes = {};
//   /// static EBDatabaseScripts scriptObj = EBDatabaseScripts();
//   static Map<String, String> traceValues = {};
//   static bool isFiltered = false;
//   static bool usingListeners = true; // Listeners are used if Projects are not filtered

//   // METHODS:
//   // --------
//   //  initialize()
//   //  list(collectionName)
//   //  evaluate(collection.fieldName)

//   static Future<bool> authenticateFirestore() async {
//     await firebase_core.Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     try {
//       final res = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(email: "jmaybee@ebusiness-solutions.ca", password: "MayaMaya123");
//       EBDatabase.firestoreAuthenticated = true;
//       return true;
//     } catch (e) {
//       print("Firestore authentication failed.  $e");
//       return false;
//     }
//   }

//   static Future<void> signOutFirestore() async {
//     await firebase_auth.FirebaseAuth.instance.signOut();
//     EBDatabase.firestoreAuthenticated = false;
//   }

//   static Future<void> initialize(EBDirectives dbDirectives) async {
//     collections = {};
//     collectionList = [];
//     collectionsByReference = {};
//     final dbSave = EBCompile.templateName;
//     for (var directive in dbDirectives) {
//       final String? collectionName = directive["name"];

//       EBDatabase.createCollection(directive);
//     }
//   }

//   static void createCollection(EBDirective directive) {
//     final String collectionName = directive["name"];

//     // These validations are only required for test scripts that don't use compiled directives
//     if (directive["parent"] == null) directive["parent"] = "";
//     if (directive["keyprefix"] == null) directive["keyprefix"] = directive["name"].substring(0, 1);
//     if (directive["sequence"] == null) directive["sequence"] = "";
//     if (directive["selected"] == null) directive["selected"] = "";
//     if (directive["from"] == null) directive["from"] = "";
//     if (directive["database"] == null) directive["database"] = "";
//     if (directive["groups"] == null) directive["groups"] = "";

//     if (directive["parent"] != "") {
//       if (!collections.containsKey(directive["parent"])) {
//         print(directive);
//         print("*** EBDatabase.initialize() error - Invalid parent name = '${directive["parent"]}'");
//         print(EBDatabase.collectionList);
//         return;
//       }

//       collections[collectionName] = EBCollection(
//           collectionName: collectionName,
//           keyName: directive["key"],
//           keyPrefix: directive["keyprefix"],
//           sequence: directive["sequence"],
//           parent: collections[directive["parent"]],
//           selected: directive["selected"],
//           from: directive["from"],
//           database: directive["database"],
//           groups: directive["groups"],
//           logFile: directive["logfile"],
//           onlineOnly: directive["onlineonly"] == "Yes");
//     } else {
//       collections[collectionName] = EBCollection(
//           collectionName: collectionName,
//           keyName: directive["key"],
//           keyPrefix: directive["keyprefix"],
//           sequence: directive["sequence"],
//           selected: directive["selected"],
//           from: directive["from"],
//           database: directive["database"],
//           groups: directive["groups"],
//           logFile: directive["logfile"],
//           onlineOnly: directive["onlineonly"]);
//     }

//     collections[collectionName]!.filterDirectives = [];
//     if (directive.containsKey("directives")) {
//       for (EBDirective enclosedDirective in directive["directives"]) {
//         if (enclosedDirective["action"] == "filter") collections[collectionName]!.filterDirectives.add(enclosedDirective);
//       }
//     }

//     final refName = collectionName.substring(0, collectionName.length - 1).toLowerCase();
//     collectionsByReference[refName] = collections[collectionName];
//     collectionList.add(collectionName);
//     collections[collectionName]!.selectedRowKey = "";
//   }

//   static Future<void> load() async {
//     // This is used for online loading from Firestore.
//     // Loading from sqfLite tables is done in EBOffline.dbLoadOffline()

//     String msg = "Loading ";

//     usingListeners = true;
//     isFiltered = false;
//     if (EBDatabase.collections.containsKey("Projects")) {
//       isFiltered = EBDatabase.collections["Projects"]!.filterDirectives.isNotEmpty;
//       usingListeners = !isFiltered;
//     }

//     for (String collectionName in collectionList) {
//       // Don't load ODL collections - If the collection is the ODL collection or it's child (On Demand Loading)

//       final EBCollection c = EBDatabase.collections[collectionName]!;
//       c.rows.clear();

//       // Check that filters are only applied to Projects collection
//       if (c.filterDirectives.isNotEmpty) {
//         if (collectionName != "Projects") {
//           msg += "*** Filters are only allowed on Projects ***";
//           c.filterDirectives = [];
//         }
//       }

//       final String msgStart = msg;

//       final DateTime startTime = DateTime.now();
//       int rowCount = 0;
//       if (!isFiltered) {
//         final query = await EBDatabase.collections[collectionName]!.fsCollection!.count().get();
//         rowCount = query.count!;

//         List<String> shardChars = [];
//         if (rowCount > 50000) {
//           shardChars = "0369CFILORUXadgjmpsvy{".split('');
//         } else if (rowCount > 9000) {
//           shardChars = "05AFKPUZejot{".split('');
//         } else {
//           shardChars = "0{".split('');
//         }
//         for (int n = 0; n < shardChars.length - 1; n++) {
//           await c.loadAndListen(shardChars[n], shardChars[n + 1], "");
//           final nLoaded = EBDatabase.collections[collectionName]!.rows.length;
//           ///EBAuth.displayProgress("$msgStart, $nLoaded ${c.collectionName}");
//         }
//       } else {
//         // Filtered
//         await c.loadFiltered();
//         if (c.rows.length == 9999) {
//           ///EBAuth.displayProgress("$msgStart, Max rows exceeded for ${c.collectionName}");
//         }
//       }

//       final DateTime endTime = DateTime.now();
//       final String nSeconds = "${endTime.difference(startTime).inSeconds}";

//       if (msg != "Loading ") msg += ", ";
//       final nLoaded = EBDatabase.collections[collectionName]!.rows.length;
//       msg += "$nLoaded ${c.collectionName}";
//       //if (!kReleaseMode) {
//       //  msg += " ($nSeconds)";
//       //}
//       // Check document count if not filtered
//       if (!isFiltered && collectionName != "Accounts" && collectionName != "Users") {
//         if (nLoaded != rowCount) {
//           msg += ", Missing = ${rowCount - nLoaded}";
//         }
//       }

//       ///EBAuth.displayProgress(msg);
//     }

//     msg += ". Completed.";
//     await Future.delayed(Duration(seconds: 2));
//     ///EBAuth.displayProgress(msg);

//     ///EBAppMenu2.selectedItem = 0;
//     ///await appController.init();
//   }

//   static bool loadAppData(String source) {
//     // String name
//     bool firstLine;
//     List<String> names; // Column (field) names
//     List<int> nameStart; // Column start positions
//     List<int> nameEnd; // Column end positions
//     List<String> sectionLines;

//     final sectionContent = EBUtil.sectionsFromString(source);

//     for (String? collectionName in sectionContent.keys) {
//       EBDatabase.collections[collectionName]!.rows = [];
//       sectionLines = sectionContent[collectionName]!.split("\n");

//       if (sectionLines[sectionLines.length - 1].trim().isEmpty) sectionLines.removeLast();

//       firstLine = true;
//       names = [];
//       nameStart = [];
//       nameEnd = [];

//       for (var line in sectionLines as Iterable<String>) {
//         if (line.trim().isEmpty) continue;
//         if (firstLine) {
//           // --- First non-comment row contains field names
//           firstLine = false;
//           names = line.split(" ");
//           names.removeWhere((item) => item == "");

//           var iName = 0;
//           for (var name in names as Iterable<String>) {
//             nameStart.add(line.indexOf(name));
//             if (iName > 0) {
//               nameEnd.add(nameStart[iName]);
//             }
//             iName += 1;
//           }
//           nameEnd.add(line.length - 1);
//         } else {
//           // --- Data row - add to collection
//           line += " " * 100;
//           String value;
//           final row = <String, String>{};
//           for (var j = 0; j < names.length; j++) {
//             if (j == names.length - 1) nameEnd[j] = line.length;
//             value = line.substring(nameStart[j], nameEnd[j]).trim();
//             row[names[j]] = value;
//             if (value.toLowerCase().endsWith(".jpg") || value.toLowerCase().endsWith(".png")) {
//               //images[value] = (await rootBundle.load("assets/images/$value")).buffer.asUint8List();
//             }
//           }
//           EBDatabase.collections[collectionName]!.add(row);
//         }
//       }
//     }
//     return true;
//   }

//   static Future<void> generateTestRows() async {
//     final p = collections["Projects"]!;
//     final i = collections["Inspections"];
//     final ph = collections["Photos"];
//     final iInspectionID = 100;
//     final iStore = 100;
//     final iPhoto = 100;
//     final markup = <String, dynamic>{"action": "drawline", "lineWidth": 2};
//     final row = <String, dynamic>{"ProjectID": "P4", "markup": markup};
//     await p.addBulk({});

//     // 100 projects x 30 = 3,000 inspections x 30 photos = 90,000 photos
//     // for (int iProject = 10; iProject< 20; iProject++) {
//     //   p.addBulk({"ProjectID": "P$iProject", "ProjectName": "Proj $iProject"});
//     //   print("===== Project P$iProject");
//     //   for (int iIns = 1; iIns <= 30; iIns++) {
//     //     i.addBulk({"ProjectID": "P$iProject", "InspectionID": "I$iInspectionID", "StoreNumber":"$iStore", "StoreName": ""});
//     //     iInspectionID += 1;
//     //     iStore += 1;
//     //     for (int iPh = 1; iPh <= 30; iPh++) {
//     //       ph.addBulk({"PhotoID": "PH$iPhoto", "InspectionID": "I$iInspectionID", "PhotoNumber": "$iPhoto", "Comments": "asd asd asd asd asd asd asd asd asd asd"});
//     //       iPhoto += 1;
//     //     }
//     //   }
//     // }

//     // EBCollection q = collections["Quotes"];
//     // EBCollection i = collections["Items"];
//     //
//     // int iItem = 100;
//     //
//     // // 100 quotes x 100 items = 10,000 inspections x 30 photos = 90,000 photos
//     // for (int iQuote = 10; iQuote <= 30; iQuote++) {
//     //   q.addBulk({"QuoteID": "Q$iQuote", "QuoteNumber": "$iQuote", "ClientName": "Client $iQuote"});
//     //   print("===== Quote Q$iQuote");
//     //
//     //   for (int j = 1; j <= 100; j++) {
//     //     i.addBulk({"ItemID": "I$iItem", "QuoteID": "Q$iQuote", "Item":"$iItem", "ItemNumber": "$iItem", "ItemName": "Item $iItem", "Cost": "\$10"});
//     //     iItem += 1;
//     //   }
//     // }
//   }

//   // getDataValue tests:

//   // <print data="=====Starting" />
//   // <print data=project.ProjectName />
//   // <print data=project.ProjectName.toLowerCase />
//   // <print data="Project = #project.ProjectName#" />
//   // <print data="Project(lc)= #project.ProjectName.toLowerCase#" />
//   // <print data="Tech reps= #settings.options.Technicians#" />
//   // <print data=#var1# />
//   // <Define name=#var1# value="This is var1" />
//   // <print data=#var1# />
//   // <print data=#var1#.toLowerCase />
//   // <Define name=#var2# value="This is var2" />
//   // <print data="Two vars #var1# and #var2#" />
//   // <print data="#var1# and #var2#" />
//   // <define name=#UsePlural# value=Yes />
//   // <print data="The #inspection/inspections# #was/were# completed." />
//   // <define name=#UsePlural# value=No />
//   // <print data="The #inspection/inspections# #was/were# completed." />

//   // getCollectionValue was added 2021-10-22 to solve a problem in devTools, where #vars# were replaced in the retrieved source memo.
//   // (which is a requirement in ILD).
//   // This code is duplicated from getDataValue, so re-factoring/ redesign is required.
//   // Perhaps there should be an option to allow/ disable the second-level replaces.

  
// }
