// @formatter:off

/*
DESIGN NOTES:
- Possible improvement to logic & efficiency by having a directive type in the dictionary?

DOCUMENTATION:
- EBExecute processes a directive, passed as a Map, for forms and repordrawMapts.
- For forms, the input widgets are generated (labels, textBoxes, etc)
- For reports, the PDF content is generated.
- This class implements the logic for:
  - Statements, such as <Define />, <if> and <repeat> are processed in this class.
  - Cursor moves are pro
*/

import 'package:flutter/material.dart';

import '../Compiler/EBTypes.dart';
//import '../form_control_widgets/button.dart';
//import '../form_control_widgets/calendar_button.dart';
//import '../form_control_widgets/checkbox.dart';
//import '../form_control_widgets/combobox.dart';
//import '../form_control_widgets/image_rotate.dart';
//import '../form_control_widgets/image_upload.dart';
//import '../form_control_widgets/image_widget.dart';
import '../form_control_widgets/label.dart';
//import '../form_control_widgets/list.dart';
//import '../form_control_widgets/lookup_button.dart';
//import '../form_control_widgets/markdown_widget.dart';
//import '../form_control_widgets/memo_control.dart';
//import '../form_control_widgets/memo_display.dart';
//import '../form_control_widgets/memo_options_button.dart';
//import '../form_control_widgets/options_button.dart';
//import '../form_control_widgets/pdf_viewer.dart';
//import '../form_control_widgets/progress_bar.dart';
//import '../form_control_widgets/progress_memo.dart';
//import '../form_control_widgets/progress_message.dart';
//import '../form_control_widgets/signature_button.dart';
//import '../form_control_widgets/signature_clear_button.dart';
//import '../form_control_widgets/textbox.dart';
//import 'EBForm.dart';
//import 'EBList.dart';
//import 'EBTabBar.dart';
//import 'package:image_size_getter/image_size_getter.dart';

class EBExecute {
  static String? generationType; // "Form" or "Report"
  static late Map<String, dynamic> setValues;
  static bool ifCondition = false;
  static bool lastIfResult = false;
  static late Map<String, dynamic> pageSize;
  static late Map<String, dynamic> margins;
  static late Map<String, dynamic> indents;
  static late Map<String, dynamic> cursor;
  static late Map<String, dynamic> savedCursors;
  static Map<String, EBDirective> labelStyles = {};
  static late Map<String, EBDirective> defineDirectives;
  static String focusControlName = "";
  static late List<Widget> ctls;
  static EBDirectives onFormLoadDirectives = [];
  static EBDirectives onChangeDirectives = [];
  static EBDirectives beforeSaveDirectives = [];
  static EBDirectives afterSaveDirectives = [];
  static EBDirectives onAddDirectives = [];
  static bool generatingList = false;
  static EBDirective drawDirective = {};
  static EBDirective controlOptions = {};
  static EBDirectives generatedFormControlList = [];
  static var lastImageLocation = {"x": 0.0, "y": 0.0, "width": 6.0, "height": 4.0};
  static Map<String, dynamic> addLastRow = {};
  //static EBCollection? addCollection;
  static Map<String, dynamic> formSettings = {};
  static double? renderingWidth = 4.0;
  static Map<String, List<dynamic>> calcSums = {};
  static Map<String, List<dynamic>> calcMult = {};
  static double? autoNewLine = 0.0;
  static late List<String> memoryTest;
  static bool traceMode = false;

  static void init() {
    pageSize = {"width": 8.5, "height": 11.0};
    margins = {"left": .5, "right": .5, "top": 1.1, "bottom": .5};
    indents = {"left": 0.0, "right": 0.0};
    cursor = {"x": margins["left"], "y": margins["top"]};
    savedCursors = {};
    labelStyles = {};
    setValues = {
      "labelfontname": "arial",
      "labelbold": true,
      "labelfontsize": 14.0,
      "labelfontcolor": "black",
      "labelalign": "left",
      "labelsabove": false,
      "labelsaboveoffset": .2,
      "labelsabovefontsize": 12.0,
      "numtext": "n",
      "numoffset": .23,
      "numfontsize": 10.0,
      "erroffset": .4,
      "errfontsize": 14.0
    };
    ctls = [];
    defineDirectives = {};

    // Get settings if Add or Edit form
    formSettings = {};
    setValues["reqdtext"] = "";
    setValues["numtext"] = "";
  }

  static void processFormDirectives(EBDirectives directives) {
    generationType = "Form";

    for (var directive in directives as Iterable<Map<dynamic, dynamic>>) {
      final dirNum = 0;
      if (directive["at"] != null) cursor["x"] = margins["left"] + indents["left"] + directive["at"];

      if (_processCommonDirective(directive)) continue;
      if (_processControlRenderingDirective(directive)) continue;
      print("EBForm: Invalid directive = $directive");
    }
  }


  // These directives set values only - cursor, define vars, etc -  and do not generate form controls
  static bool _processCommonDirective(directive) {
    switch (directive["action"].toLowerCase()) {
     
      case "setpagesize":
        pageSize = {"width": directive["width"], "height": directive["height"]};
        break;

      case "setmargins":
        if (directive.containsKey("left")) margins["left"] = directive["left"];
        if (directive.containsKey("right")) margins["right"] = directive["right"];
        if (directive.containsKey("top")) margins["top"] = directive["top"];
        if (directive.containsKey("bottom")) margins["bottom"] = directive["bottom"];
        break;

      case "setindent":
        if (directive.containsKey("left")) indents["left"] = directive["left"];
        if (directive.containsKey("right")) indents["right"] = directive["right"];
        break;

      case "movetop":
        cursor = {"x": margins["left"] + indents["left"], "y": margins["top"]};
        //debugResult("cursor", cursor.toString());
        break;

      case "movebottom":
        cursor = {"x": margins["left"] + indents["left"], "y": pageSize["height"] - margins["bottom"]};
        //debugResult("cursor", cursor.toString());
        break;

      case "moveleft":
        if (directive.containsKey("distance")) {
          cursor["x"] -= directive["distance"];
        } else {
          cursor["x"] = margins["left"] + indents["left"];
        }
        //debugResult("cursor", cursor.toString());
        break;

      case "moveright":
        cursor["x"] += directive["distance"];
        //debugResult("cursor", cursor.toString());
        break;

      case "moveup":
        cursor["y"] -= directive["distance"];
        break;

      case "movedown":
        cursor["y"] += directive["distance"];
        //debugResult("cursor", cursor.toString());
        break;

      case "moveabsolute":
        cursor = {"x": directive["across"], "y": directive["down"]};
        //debugResult("cursor", cursor.toString());
        break;

      case "savecursor":
        savedCursors[directive["name"]] = Map.from(cursor);
        break;

      case "savemaxcursor":
        final String? name = directive["name"];
        if (!savedCursors.containsKey(name)) {
          savedCursors[name!] = {"x": 0.0, "y": 0.0};
        }
        if (cursor["y"] > savedCursors[name]["y"]) {
          savedCursors[name!] = Map.from(cursor);
        }
        break;

      case "restorecursor":
        final String? name = directive["name"];
        if (savedCursors.containsKey(name)) {
          cursor = Map.from(savedCursors[name]);
        } else {
          print("RestoreCursor error - invalid name = '$name'");
        }
        //debugResult("cursor", cursor.toString());
        break;

      default:
        return false;
        break;
    }
    return true;
  }

  // These directives generate the form control widgets, adding to ctls[]
  static bool _processControlRenderingDirective(directive) {
    String? action = directive["action"].toLowerCase();
    if (action == "drawtext") {
      directive["action"] = "drawlabel";
      action = "drawlabel";
    }
    if (["drawline", "drawarrow", "drawcircle", "drawrect", "drawbox", "drawpolygon", "drawphotolocn", "drawsymbol"].contains(action)) {
      action = "drawxxxx";
    }

    switch (action) {
      case "drawlabel":

        String? text = directive["label"] + directive["data"];
        ///text = EBDatabase.evaluate(directive["prefix"])! + EBDatabase.evaluate(text)! + EBDatabase.evaluate(directive["suffix"])!;
        if (directive.containsKey("rightalign")) {
          if (directive["rightalign"]) {
            cursor["x"] = EBExecute.renderingWidth! - directive["width"];
          }
        }
        // The directive is passed as the style argument, since the style attributes have been copied, or possibly overridden
        ctls.add(Label(x: cursor["x"], y: cursor["y"], text: text, style: directive));
        if (EBExecute.autoNewLine! > 0) {
          cursor["x"] = margins["left"] + indents["left"];
          cursor["y"] += EBExecute.autoNewLine;
        } else {
          cursor["x"] += directive["width"];
        }
        break;

      

      default:
        return false;
    }
    return true;
  }

}
