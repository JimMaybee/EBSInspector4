// // @formatter:off
// import 'package:flutter/cupertino.dart';

// import '../../extensions.dart';
// import '../../widgets/alert.dart';
// // ignore: unused_import
// import '../Compiler/EBCompile.dart';
// import '../Compiler/EBTypes.dart';
// import '../Other/EBUtil.dart';
// import 'EBExecute.dart';

// class EBForm extends StatefulWidget {
//   EBForm(
//       {super.key,
//       this.x,
//       this.y,
//       this.height,
//       this.width,
//       this.title,
//       this.templateName,
//       this.navBar,
//       this.scroll,
//       this.viewOnly,
//       this.directives,
//       this.withoutSplitView});
//   static bool isActive = false;
//   static String? activeCollectionName = "";
//   static String? collectionName = "";
//   static String formState = "Display"; // Display, Add or Edit
//   static bool isAdding = false; // Used to avoid double adds.
//   static Map<String, String?> formData = {};
//   static String? get(fld) {
//     return formData.containsKey(fld) ? formData[fld] : "";
//   }

//   static double varValue = 0;
//   static bool ifCondition = false;
//   static bool lastIfResult = false;
//   static Map<String, TextEditingController> textBoxControllers = {};
//   static Map<String, bool> reqdInputs = {};
//   static bool errorFound = false;
//   static Map<String, String> errorMessages = {};
//   static Map<String, String> imageSizes = {};
//   static String testResults = "";
//   static int testErrorCount = 0;
//   static bool editDisabledSet = false; // Set by <Set EditDisabled/>

//   final double? x, y;
//   double? width, height;
//   final String? title;
//   final String? templateName;
//   final bool? navBar;
//   final bool? scroll;
//   final bool? viewOnly;
//   final bool? withoutSplitView;
//   final EBDirectives? directives;

//   @override
//   _EBFormState createState() => _EBFormState();
// }

// class _EBFormState extends State<EBForm> {
//   final scrollController = ScrollController();
//   Widget? pageScaffold;

//   Widget leftButton() {
//     return GestureDetector(
//       child: Padding(
//         // The left nav menu bar isn't positioned correctly by Flutter !!
//         padding: const EdgeInsets.symmetric(vertical: 7.0),
//         child: Text(EBForm.formState == "Display" ? "" : " Cancel ", style: TextStyle(fontSize: 24, color: CupertinoColors.activeBlue)),
//       ),
//       onTap: () async {
//         // Cancel
//         EBForm.formState = "Display";
//         EBForm.isActive = false;

//         ///EBAppController.inModal = false;
//         ///appController.reloadApp();
//         EBForm.errorMessages = {};
//       },
//     );
//   }

//   Widget? rightButton() {
//     var viewOnly = widget.viewOnly;
//     if (widget.viewOnly == null) viewOnly = false;
//     if (viewOnly!) return null;

//     ///collectionName = widget.templateName!.replaceAll("Form", "s").removeFrom("_"); // ProjectForm ==> Projects
//     var editDisabled = false;

//     /// EBDatabase.collections[collectionName]!.selectedRowKey!.isEmpty || EBAppController.inModal || EBForm.editDisabledSet;
//     if (EBForm.formState != "Display") editDisabled = false;
//     final text = (EBForm.formState == "Display") ? " Edit " : " Save ";
//     final style = TextStyle(fontSize: 24, color: editDisabled ? CupertinoColors.inactiveGray : CupertinoColors.activeBlue);
//     return GestureDetector(
//       child: Text(text, style: style),
//       onTap: () async {
//         final request = (EBForm.formState == "Display") ? "Edit" : "Save";
//         switch (request) {
//           case "Edit": // Edit request
//             if (!editDisabled) {
//               // if (EBDatabase.online && !(await EBUtil.isConnected())) {
//               //   await alert(context: context, title: "Edit is not available", message: "Internet connection is required.");
//               //   return;
//               // }

//               //EBAppController.inModal = true;
//               EBForm.formState = "Edit";
//               EBForm.isActive = true;

//               ///EBForm.activeCollectionName = collectionName;
//               // Remove 2024-04-11 After implementing <drawTextBox ... lookup />
//               // Was used for options=collection.fieldName.  Template search didn't find any uses
//               //await EBExecute.setOptionLists(EBAppController.compiledTemplate[widget.templateName]);
//               EBForm.formData = {}; //Map.from(collection!.selectedRow());
//               reload();
//               //appController.reloadApp();
//             }
//             break;

//           case "Save":
//             // if (EBDatabase.online && !(await EBUtil.isConnected())) {
//             //   await alert(
//             //       context: context,
//             //       title: "Unable to Save",
//             //       message: "Internet connection has been lost.\nPlease Cancel or restore connection\nand Save again.");
//             //   return;
//             // }

//             await save();
//             break;
//         }
//       },
//     );
//   }

//   Future<void> save() async {
//     // Validate
//     EBForm.errorFound = false;
//     EBForm.errorMessages = {};

//     // Reqd validation, unless disabled in settings
//     if (EBDatabase.evaluate("settings.preferences.IgnoreReqd") != "Yes") {
//       for (var ctl in EBForm.reqdInputs.keys) {
//         if (EBForm.formData.containsKey(ctl)) {
//           if (EBForm.formData[ctl]!.isEmpty) {
//             EBForm.errorMessages[ctl] = "Input required";
//             EBForm.errorFound = true;
//           }
//         }
//       }
//     }
//     if (EBForm.errorFound) {
//       //await EBUtil.alert(context, "Input errors", "Please check the form for errors and re-save.");
//       reload();
//     } else {
//       ///await EBExecute.executeBeforeSaveDirectives();
//       if (EBForm.formState == "Add") {
//         // Add save
//         if (EBForm.isAdding) return;
//         EBForm.isAdding = true;
//         final Map<String, dynamic> lastRow = collection!.lastRow();
//         await collection!.add(EBForm.formData);
//         await EBExecute.executeOnAddDirectives(collection, lastRow);
//         collection!.selectedRowKey = collection!.lastAddedRow[collection!.keyName];
//       } else {
//         // Edit Save
//         if (!collection!.rowExists(EBForm.formData)) {
//           await EBUtil.alert(context, "Save error", "This row has been deleted by another user. Changes cannot be saved");
//         } else {
//           await collection!.update(EBForm.formData);
//         }
//       }
//       await EBExecute.executeAfterSaveDirectives();
//       EBAppController.inModal = false;
//       EBForm.formState = "Display";
//       EBForm.isActive = false;
//       reload();
//       appController.reloadApp();
//       EBForm.isAdding = false;
//     }
//   }

//   List<Widget> controls() {
//     //formName = widget.templateName;
//     collectionName = widget.templateName!.replaceAll("Form", "s").removeFrom("_"); // ProjectForm ==> Projects
//     EBForm.collectionName = collectionName;
//     //initialFormData = Map.from(EBForm.formData);
//     collection = EBDatabase.collections[collectionName];
//     if (EBForm.formState == "Display") {
//       if (collection != null) {
//         EBForm.formData = Map.from(collection!.selectedRow());
//       }
//     }
//     EBExecute.init();
//     if (EBForm.formState != "Display") {
//       EBForm.reqdInputs = {};

//       if (collectionName == EBForm.activeCollectionName) {
//         EBExecute.beforeSaveDirectives = [];
//         EBExecute.onChangeDirectives = [];
//         EBExecute.onAddDirectives = [];
//       }
//     } else {
//       EBForm.errorMessages = {};
//     }

//     var ctls = <Widget>[];
//     // AutoExecute
//     if (EBAppController.compiledTemplate.containsKey("AutoExecute")) {
//       EBExecute.processFormDirectives(EBAppController.compiledTemplate["AutoExecute"]!);
//       ctls += EBExecute.ctls;
//     }

//     EBExecute.processFormDirectives(EBCompile.compiledTemplate[widget.templateName]!);
//     ctls += EBExecute.ctls;

//     return ctls;
//   }

//   Widget form() {
//     Widget formWidget;

//     if (widget.scroll!) {
//       formWidget = Align(
//           alignment: Alignment.topLeft,
//           child: Padding(
//               padding: EdgeInsets.only(top: 0, right: 14),
//               child: SingleChildScrollView(
//                   controller: scrollController,
//                   child: Align(
//                       alignment: Alignment.topLeft,
//                       child: Padding(
//                         padding: const EdgeInsets.only(bottom: 72.0),
//                         child: Stack(children: controls()),
//                       )))));
//     } else {
//       formWidget = Align(
//           alignment: Alignment.topLeft,
//           child: Padding(
//               padding: EdgeInsets.only(top: 0, right: 14),
//               child: Align(
//                   alignment: Alignment.topLeft,
//                   child: Padding(
//                     padding: const EdgeInsets.only(bottom: 72.0),
//                     child: Stack(children: controls()),
//                   ))));
//     }

//     //bool formInForm = (widget.directives.isNotEmpty);
//     //print("FormInForm not implemented");
//     final formInForm = false;
//     if (formInForm) {
//       //Override for drawForm
//       formWidget = Padding(
//         padding: EdgeInsets.only(left: 0.0, top: widget.y! * 0.0),
//         child: SizedBox(
//             width: widget.width! * 72,
//             height: widget.height! * 72,

//             //child: Scrollbar(
//             child: Padding(
//                 padding: EdgeInsets.only(top: 0, right: 14),
//                 child: SingleChildScrollView(primary: false, child: Align(alignment: Alignment.topLeft, child: Stack(children: controls()))))),
//       );
//     }

//     // Check for empty form
//     if (EBForm.formState == "Display") {
//       if (collection!.selectedRowKey!.isEmpty) {
//         var msg = "an item";
//         if (collection!.collectionName == "Projects") msg = "a project";
//         if (collection!.collectionName == "Inspections") msg = "an inspection";
//         if (collection!.collectionName == "Photos") msg = "a photo";
//         var listRowsCount = 0;
//         if (collection!.isChild) {
//           listRowsCount = collection!.parent!.childCount(collection!.parent!.selectedRowKey);
//         } else {
//           listRowsCount = collection!.rows.length;
//         }

//         formWidget = Center(child: Text("Please ${listRowsCount == 0 ? "add" : "select"} $msg", style: TextStyle(fontSize: 16)));
//       }
//     }
//     return formWidget;
//   }

//   Widget createPageScaffold() {
//     if (widget.withoutSplitView!) {
//       EBForm.formState = "Edit";
//       return Align(
//           alignment: Alignment.topLeft,
//           child: Padding(
//               padding: EdgeInsets.only(top: 0, right: 14),
//               child: SingleChildScrollView(controller: scrollController, child: Align(alignment: Alignment.topLeft, child: Stack(children: controls())))));
//     } else {
//       //EBForm.formState = "Display";
//       return CupertinoPageScaffold(
//           navigationBar: CupertinoNavigationBar(leading: leftButton(), middle: Text(widget.title!), trailing: rightButton()), child: form());
//     }
//   }

//   @override
//   void initState() {
//     appController.addListener(reload);
//     pageScaffold = createPageScaffold();
//     super.initState();
//   }

//   @override
//   void didUpdateWidget(oldWidget) {
//     //if (EBForm.formState == "Display") {
//     if (collection != null) {
//       if (EBForm.formState == "Display") EBForm.formData = Map.from(collection!.selectedRow());
//       pageScaffold = createPageScaffold();
//     }
//     //}
//     super.didUpdateWidget(oldWidget);
//   }

//   @override
//   void dispose() {
//     appController.removeListener(reload);
//     super.dispose();
//   }

//   void reload() {
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     //debugPrint("--- Build form 1 $collectionName  ${DateTime.now()}");
//     return createPageScaffold();
//   }
// }
