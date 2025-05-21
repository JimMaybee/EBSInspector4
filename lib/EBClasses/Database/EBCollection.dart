// // @formatter:off

// import 'dart:async';
// import 'dart:math';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:validators/validators.dart';
// import '../../extensions.dart';
// import '../Compiler/EBCompile.dart';
// import '../Compiler/EBTypes.dart';
// import '../Other/EBUtil.dart';
// import 'EBDatabase.dart';

// class EBCollection extends ChangeNotifier {

//   EBCollection(
//       {required this.collectionName,
//       required this.keyName,
//       required this.keyPrefix,
//       required this.sequence,
//       this.parent,
//       this.selected,
//       required this.from,
//       this.database,
//       this.groups,
//       this.logFile,
//       this.onlineOnly}) {
//     // Set defaults for parent properties - If a child object is instantiated, these will be updated
//     isParent = false;
//     child = null;
//     isChild = false;
//     if (parent != null) {
//       isChild = true;
//       parent!.isParent = true;
//       parent!.child = this;
//     }
//     var dbName = EBCompile.templateName;
//     if (database == null) {
//       dbName = EBCompile.templateName;
//     } else if (database!.isNotEmpty) {
//       dbName = database;
//     }

//     if (groups!.isNotEmpty) {
//       groupNames = {};
//       var groupsToBeUsed = groups;
//       if (collectionName == "Photos") {
//         groupsOverride = "";
//         groupsToBeUsed = groupsOverride;
//       }
//       for (var groupName in groupsToBeUsed!.split(",")) {
//         final iGroup = groupName.leadingDigits();
//         groupNames[iGroup] = groupName;
//       }
//     }
//     rows = [];
//     if (EBDatabase.online) {
//       //  appData/authentication/users
//       //  templates
//       if (dbName == "templates" && (EBAuth.templateName == "sysAdmin" || EBAuth.templateName == "devTools")) {
//         fsCollection = FirebaseFirestore.instance.collection(collectionName.toLowerCase());
//       } else if (dbName == "directives") {
//         fsCollection = FirebaseFirestore.instance.collection("directives");
//       } else if (dbName == "dirtests") {
//         fsCollection = FirebaseFirestore.instance.collection("dirtests");
//         //} else if (dbName == "tasks") {
//         //  fsCollection = FirebaseFirestore.instance.collection("tasks");
//         // } else if (dbName == "devProjects") {
//         //   fsCollection = FirebaseFirestore.instance.collection("devProjects");
//         // } else if (dbName == "devTests") {
//         //   fsCollection = FirebaseFirestore.instance.collection("devTests");
//       } else if (dbName == "exportLogs") {
//         fsCollection = FirebaseFirestore.instance.collection("exportLogs");
//       } else if (dbName == "metrics") {
//         fsCollection = FirebaseFirestore.instance.collection("metrics");
//       } else if (dbName == "deviceTemplates") {
//         fsCollection = FirebaseFirestore.instance.collection("deviceTemplates");
//       } else {
//         if (logFile!) {
//           fsCollection = FirebaseFirestore.instance.collection("appLog").doc(dbName).collection(collectionName.toLowerCase());
//         } else {
//           fsCollection = FirebaseFirestore.instance.collection("appData").doc(dbName).collection(collectionName.toLowerCase());
//           fsTransactionLog = FirebaseFirestore.instance.collection("appLog").doc(dbName).collection(collectionName.toLowerCase());
//         }
//       }
//     }
//   }
//   // PROPERTIES:
//   final String collectionName;
//   final String? keyName; // The primary key name.
//   final String? keyPrefix; // Prefix assigned to new rows by add() method.
//   final String? sequence;
//   String? selected = "";
//   final String? from;
//   EBDirectives filterDirectives = [];
//   final String? database;
//   final String? groups;
//   final bool? logFile;
//   final bool? onlineOnly;

//   String groupsOverride = "";
//   late Map<int, String> groupNames;
//   bool batchUpdateActive = false;
//   Map<String, Map<String, String?>> batchRows = {};

//   // Parent child properties - set by constructor
//   late bool isChild;
//   EBCollection? parent; // The parent EBCollection
//   late bool isParent;
//   EBCollection? child; // The child EBCollection - set when the child is instantiated

//   // Firestore collection - Used if EBDatabase.online
//   CollectionReference<EBDirective>? fsCollection;
//   CollectionReference<EBDirective>? fsTransactionLog;

//   // Properties set during usage
//   List<Map<String, String?>> rows = []; // Filtered rows in the collection.
//   String? selectedRowKey; // primary key of the selected row
//   String? savedSelectedRowKey;
//   Map<String, String?> lastAddedRow = {};
//   EBDirective optionLists = {};
//   List<String> userFilters1 = [];
//   List<String> userFilters2 = [];
//   String? userSortField = "";
//   bool userSortAscending = true;
//   List<TextEditingController> filterComboBoxControllers = [TextEditingController(text: "")];
//   int filterComboxFocus = 0;
//   Map<String, int> childRowCounts = {};

//   List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> firestoreListeners = [];
//   bool childOndemandLoading = false;
//   List<String> childOndemandDocumentsLoaded = [];

//   Future<void> loadAndListen(String shard1, String shard2, String parentKey) async {
//     if (shard1.isEmpty && shard2.isEmpty) {
//       shard1 = "0"; // Reset to get all documents
//       shard2 = "{";
//     }
//     var query = fsCollection!.where(FieldPath.documentId, isGreaterThanOrEqualTo: shard1).where(FieldPath.documentId, isLessThan: shard2);
//     if (parentKey.isNotEmpty) {
//       query = query.where(parent!.keyName!, isEqualTo: parentKey);
//       debugPrint("****** EBCollection.loadAndListen where added ???  $collectionName  $parentKey ");
//     }

//     if ((collectionName == "Accounts" || collectionName == "Users") && EBAuth.templateName != "sysAdmin") {
//       query = query.where("AccountID", isEqualTo: EBAuth.accountName);
//     }

//     // A Completer object is used to complete the initial document loading.
//     var nRows = 0;
//     final loadRows = Completer<void>();
//     late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listener;
//     listener = query.snapshots().listen((querySnapshot) async {
//       Map<String, String?> row;

//       for (final change in querySnapshot.docChanges) {
//         row = {};
//         var nRow = 0;
//         final nTotal = change.doc.data()!.length;
//         for (String? key in change.doc.data()!.keys) {
//           if (key!.contains(".")) continue;
//           if (change.doc.data()![key] is! String) {
//             //debugPrint(
//             //    "=== loadAndListen Not a String ${collection!.collectionName} ID=${change.doc.data()![collection!.keyName]})  field=$key\ndata=${change.doc.data()![key]}");
//           } else {
//             try {
//               row[key] = change.doc.get(key);
//               nRow += 1;
//             } catch (e) {
//               debugPrint("==== Error:\n----- e= $e\n----- key=$key\n----- var=${change.doc.get(key)}");
//             }
//           }
//         }

//         if (loadRows.isCompleted) {
//           // This is listener event after the initial loading.
//           if (change.type == DocumentChangeType.added) {
//             add2(row);
//           } else if (change.type == DocumentChangeType.modified) {
//             update2(row);
//           } else if (change.type == DocumentChangeType.removed) {
//             delete2(row);
//           }
//           // EBDatabase.applyDatabaseFilters();
//           if (!EBAppController.inModal) appController.reloadApp();
//         } else {
//           nRows += 1;
//           rows.add(row);
//         }
//       }
//       if (!loadRows.isCompleted) {
//         loadRows.complete();
//       }
//     });

//     await loadRows.future; // Waits until the above loadRows.complete() is called.
//     shard1 = "0"; // Reset to get all documents
//     shard2 = "{";
//     firestoreListeners.add(listener);
//     return;
//   }

//   Future<void> loadFiltered() async {
//     // This is used when the Projects collection is filtered, such as ILD filtering to AssignedRep
//     Map<String, String?> row;
//     var query = fsCollection!.limit(9999);
//     if (!isChild) {
//       if (collectionName == "Projects") {
//         // Add Projects filters to the query
//         String fieldName;
//         String equalTo;
//         for (EBDirective directive in filterDirectives) {
//           fieldName = "";
//           if (directive.containsKey("field")) fieldName = directive["field"];
//           if (fieldName.isNotEmpty) {
//             equalTo = EBDatabase.evaluate(directive["equalto"])!;
//             if (equalTo.isNotEmpty) {
//               query = query.where(fieldName, isEqualTo: equalTo);
//             }
//           }
//         }
//       }

//       await query.get().then((querySnapshot) {
//         for (var doc in querySnapshot.docs) {
//           row = {};
//           for (var key in doc.data().keys) {
//             row[key] = doc.data()[key];
//           }
//           rows.add(row);
//         }
//       });
//     } else {
//       // child collection - Query rows for each parent
//       for (Map<String, String?> parentRow in parent!.rows) {
//         final query = fsCollection!.where(parent!.keyName!, isEqualTo: parentRow[parent!.keyName]);

//         await query.get().then((querySnapshot) {
//           for (var doc in querySnapshot.docs) {
//             row = {};
//             for (var key in doc.data().keys) {
//               row[key] = doc.data()[key];
//             }
//             rows.add(row);
//           }
//         });
//       }
//     }
//   }

//   Map<String, String?> selectedRow() {
//     for (var row in rows) {
//       if (row[keyName] == selectedRowKey) {
//         return row;
//       }
//     }
//     return {};
//   }


//   bool _exists(String key) {
//     for (var row in rows) {
//       if (row[keyName] == key) {
//         return true;
//       }
//     }
//     return false;
//   }

//   bool exists(String key) {
//     for (var row in rows) {
//       if (row[keyName] == key) {
//         return true;
//       }
//     }
//     return false;
//   }

//   Future<void> add(Map<String, String?> newRow) async {

//     String? keyValue = "";
//     if (collectionName == "Accounts" && EBAuth.templateName == "sysAdmin" && newRow.containsKey("AccountID")) {
//       keyValue = newRow["AccountID"];
//     } else if (!newRow.containsKey(keyName)) {
//       if (EBDatabase.testMode) {
//         String? key;
//         var maxKey = 0;
//         for (EBDirective row in rows) {
//           key = row[keyName];
//           if (key!.startsWith(keyPrefix!)) {
//             if (!isNumeric(key.substring(keyPrefix!.length))) continue;
//             maxKey = max(maxKey, int.parse(key.substring(keyPrefix!.length)));
//           }
//         }
//         keyValue = "$keyPrefix${maxKey + 1}";
//       } else {
//         keyValue = EBUtil.generateKey();
//       }
//     } else {
//       keyValue = newRow[keyName];
//     }

//     final addRow = <String, String?>{keyName!: keyValue};

//     // Set foreign key to selected parent row, if child
//     if (isChild) {
//       addRow[parent!.keyName!] = parent!.selectedRowKey;
//     }

//     // Copy remaining fields
//     for (String? key in newRow.keys) {
//       if (key != keyName) addRow[key!] = newRow[key];
//     }

//     if (EBDatabase.online) {
//       addRow["@Timestamp"] = "${EBUtil.timeStamp()}";
//     } else {
//       addRow["SyncReqd"] = "Yes";
//     }

//     if (EBAuth.demoUser) {
//       add2(addRow);
//     } else if (EBDatabase.online) {
//       final isConnected = await EBUtil.isConnected();
//       if (isConnected) {
//         await fsCollection!.doc(keyValue).set(addRow);
//         debugPrint("--- Added to Firestore, usingListeners = ${EBDatabase.usingListeners}");
//         if (!EBDatabase.usingListeners) add2(addRow);
//       } else {
//         await fsCollection!.doc(keyValue).set(addRow);
//         //await add2(addRow);
//       }

//     }
//     lastAddedRow = addRow;

//     // Add the listener if required
//     if (childOndemandLoading) {
//       //await child!.loadAndListen("", "", keyValue!);
//     }
//     //EBDatabase.scriptObj.executeScript("${collectionName}_Add");
//   }

//   void add2(Map<String, String?> newRow) {
//     // async removed 2022-08-28
//     rows.add(newRow);
//     //EBDatabase.applyDatabaseFilters();

//     ///selectedRowKey = newRow[keyName];

//     ///clearChildSelectedRows();
//     //       image = await s.getFromOnline(fn);
//     //       await s.saveToDevicePhotos(image, fn);

//     ///notifyListeners();
//   }

//   Map<String, String?>? _find(String? key) {
//     for (Map<String, String?> row in rows) {
//       if (row[keyName] == key) {
//         return row;
//       }
//     }
//     print("*** _find: $key not found in $collectionName length = ${rows.length}");
//     return null;
//   }

//   bool rowExists(Map<String, String?> findRow) {
//     final findKey = findRow[keyName];

//     for (EBDirective row in rows) {
//       if (row[keyName] == findKey) {
//         return true;
//       }
//     }
//     return false;
//   }

//   Future<bool> update(Map<String, String?> revisedRow0) async {
//     if (isParent) {
//       // Check that child data isn't present (Due to unknown defect)
//       if (revisedRow0.containsKey(child!.keyName)) {
//         if (!kReleaseMode) {
//           //await alert(context: EBAppController.context!, title: "Warning", message: "Projects collection contains Inspection fields.");
//           debugPrint("********** Warning: $collectionName contains child ${child!.collectionName} keyName ${child!.keyName}. **********");
//           debugPrint("$revisedRow0");
//         }
//       }
//     }
//     final revisedRow = Map<String, String>.from(revisedRow0);
//     // Save defineVars
//     for (String? key in revisedRow0.keys) {
//       if (key!.startsWith("#") && key.endsWith("#")) {
//         EBDatabase.defineVars[key] = revisedRow0[key]!;
//         revisedRow.remove(key);
//       }
//     }

//     // Find the row
//     final row = Map<String, String?>.from(_find(revisedRow[keyName])!);

//     // If update has been called with the EBCollection row (which shouldn't be done),
//     // then the update is required, since it is not possible to determine if there is a change.
//     final msg = "@Seq=${row["@Seq"]} PhotoID=${row["PhotoID"]} PhotoNumber=${row["PhotoNumber"]}";
//     if (identical(revisedRow0, row)) {
//       debugPrint("UPDATED(EBCollection row passed) $msg");
//     } else {
//       // Compare fields in revisedRow to existing row
//       var match = true;
//       for (var key in revisedRow.keys) {
//         if (!row.containsKey(key)) {
//           //debugPrint("UPDATED(Missing field $key) $msg");
//           match = false;
//           break;
//         } else {
//           if (row[key] != revisedRow[key]) {
//             //debugPrint("UPDATED($key revised ${row[key]} to ${revisedRow[key]} $msg");
//             match = false;
//             break;
//           }
//         }
//       }

//       if (match) {
//         return true;
//       }
//     }

//     // Only the provided fields are changed
//     for (var key in revisedRow.keys) {
//       row[key] = revisedRow[key];
//     }

//     if (EBDatabase.online) {
//       row["@Timestamp"] = "${EBUtil.timeStamp()}";
//     } else {
//       row["SyncReqd"] = "Yes";
//     }

//     final isConnected = await EBUtil.isConnected();
//     if (batchUpdateActive) {
//       update2(row);
//       batchRows[row[keyName]!] = row;
//     } else if (EBAuth.demoUser) {
//       update2(row);
//     } else if (EBDatabase.online) {
//       if (isConnected) {
//         final keyValue = revisedRow[keyName];
//         await fsCollection!.doc(keyValue).set(row);
//         if (!EBDatabase.usingListeners) update2(row);
//       } else {
//         await fsCollection!.doc(revisedRow[keyName]).set(row);
//       }
//     } else if (!EBDatabase.online) {
//       await EBDatabase.sqfLite.update(collectionName, row);
//       update2(row);
//     } else {
//       update2(row);
//     }
//     //await EBUtil.logDatabaseMetrics("Update", collectionName, revisedRow);
//     notifyListeners();
//     return true;
//   }

//   //Future<bool> update2(Map<String, String> revisedRow) async {
//   bool update2(Map<String, String?> revisedRow) {
//     // Find the row
//     final allRow = _find(revisedRow[keyName]);

//     if (allRow == null) {
//       print("*** EBCollection.update2 error - row not found $revisedRow");
//       return false;
//     }

//     // Update row and save any urls that may require download
//     for (String key in revisedRow.keys) {
//       allRow[key] = revisedRow[key]!;
//     }

//     //EBDatabase.applyDatabaseFilters();

//     //print("--- EBCollection: document updated = $collectionName-${revisedRow[keyName]}");

//     ///notifyListeners();
//     return true;
//   }

//   Future<bool> delete(Map<String, String?> deleteRow) async {
//     // Find the row
//     int iRow;
//     var found = false;
//     final deleteKey = deleteRow[keyName];
//     Map<String, String?> rowBeforeDelete;
//     for (iRow = 0; iRow < rows.length; iRow++) {
//       if (rows[iRow][keyName] == deleteKey) {
//         found = true;
//         rowBeforeDelete = rows[iRow];
//         break;
//       }
//     }

//     if (!found) {
//       print("*** EBCollection.delete error - row $deleteKey not found\n$deleteRow");
//       return false;
//     }

//     if (isParent) {
//       // Delete child rows, moving from last to first so that deleted rows don't mess up index references
//       // Child delete is recursive, working through all child collections.
//       for (var iChildRow = child!.rows.length - 1; iChildRow >= 0; iChildRow--) {
//         if (child!.rows[iChildRow][keyName] == deleteRow[keyName]) {
//           await child!.delete(child!.rows[iChildRow]);
//         }
//       }
//     }
//     if (EBAuth.demoUser) {
//       delete2(deleteRow);
//     } else if (EBDatabase.online) {
//       final isConnected = await EBUtil.isConnected();
//       if (isConnected) {
//         await fsCollection!.doc(deleteKey).delete();
//         if (!EBDatabase.usingListeners) delete2(deleteRow);
//       } else {
//         await fsCollection!.doc(deleteKey).delete();
//       }
//     } else {
//       // Offline
//       await EBDatabase.sqfLite.delete(collectionName, deleteRow);
//       delete2(deleteRow);
//     }
//     return true;
//   }

//   void startBatch() {
//     batchUpdateActive = EBDatabase.online; // Batch updates are only allowed in online
//     batchRows = {};
//   }

//   Future<void> updateBatch() async {
//     if (!batchUpdateActive) return;
//     final batch = FirebaseFirestore.instance.batch();
//     var nTotal = 0;
//     Map<String, String?>? doc;
//     for (String? key in batchRows.keys) {
//       doc = batchRows[key];
//       batch.update(fsCollection!.doc(doc![keyName]), doc);
//       nTotal += 1;
//     }
//     await batch.commit();
//     batchUpdateActive = false;
//     batchRows = {};
//   }

//   bool delete2(EBDirective deleteRow) {
//     // Find the row
//     int iRow;
//     var found = false;
//     final String? deleteKey = deleteRow[keyName];
//     for (iRow = 0; iRow < rows.length; iRow++) {
//       if (rows[iRow][keyName] == deleteKey) {
//         found = true;
//         break;
//       }
//     }

//     if (!found) {
//       print("*** EBCollection.delete2 error - row not found $deleteRow");
//       return false;
//     }

//     rows.removeAt(iRow);

//     //EBDatabase.applyDatabaseFilters();
//     return true;
//   }


//   Map<String, String?> cvt(doc) {
//     // Converts a query document to Map, and gets missing image names
//     var row = <String, String?>{};
//     final EBDirective d = doc.data();
//     row = {};
//     for (var fld in d.keys) {
//       try {
//         row[fld] = doc[fld];
//       } catch (e) {
//         row[fld] = "";
//         debugPrint("*** Firestore error getting Photos for CopyPhotos $fld $e ***");
//       }
//     }
//     return row;
//   }

// }
