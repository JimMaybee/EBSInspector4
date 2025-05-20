// @formatter:off

// EBDictionary
//  - Compiles the directive dictionary from bundle.

// METHODS:
//   - compile(filename)
//   - getSectionType(sectionName)
//   - validate(directive)
//   - list

import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:flutter/foundation.dart';
import 'package:validators/validators.dart';

import '../../extensions.dart';
import '../Other/EBUtil.dart';
import 'EBCompile.dart';
import 'EBTypes.dart';

// @formatter:off
class EBDictionary {
  EBDictionary();
  static Map<String, Map<String, Map<String, String>>> dictionary = {};
  static Map<String, Map<String, Map<String, String>>> helpDictionary = {};
  static List<String> fontNameList = []; // Valid font names from dictionary #define
  static List<String> colorList = []; // Valid color list from dictionary #define

  // ======================= compile() method ================================================================
  static Future<void> compile(String dictionaryContents) async {
    // The directive dictionary is loaded from dictionary.txt into dictionary[sectionName][directiveName][attrName] = valCodes
    // See dictionary.txt for documentation.

    // String dictionaryContents = await rootBundle.loadString("assets/$filename");
    dictionaryContents = dictionaryContents.removeComments();
    final List<String> dictionaryLines = dictionaryContents.split("\n");

    final nameStart = []; // List of column starts
    final nameEnd = []; // List of column ends
    var firstRow = true;
    String dictionarySection;
    String? dictionaryDirective;
    String dictionaryAttributes;
    var activeSectionName = "";
    String attrName;
    String attrValCodes;
    dictionary = {};

    for (var line in dictionaryLines as Iterable<String>) {
      if (line.toLowerCase().trimLeft().startsWith("#define ")) {
        // #define directive:
        //   #define colors = Red, Green, Blue, ...
        //   #define fonts = TimeNewRoman, Arial, ...
        line = line.trim();
        final iPt = line.indexOf("=");

        if (iPt == -1) {
          EBCompile.logError("DICTIONARY ERROR - Missing '=' in #define '$line");
        } else {
          final varName = line.substring(8, iPt).toLowerCase().trim();
          final List<String> varValues = line.substring(iPt + 1).trim().split(",");

          if (varName == "fontnames") {
            fontNameList = [];
            for (var font in varValues as Iterable<String>) {
              fontNameList.add(font.trim().toLowerCase());
            }
          } else if (varName == "colors") {
            colorList = [];
            for (var color in varValues as Iterable<String>) {
              colorList.add(color.trim().toLowerCase());
            }
          } else {
            EBCompile.logError("DICTIONARY ERROR - INVALID Define = '$dictionaryDirective  (must be fontNames or Colors)");
          }
        }
        continue;
      }

      if (firstRow) {
        // Set the column positions from the first row
        final List<String> names = line.split(" ");
        names.removeWhere((item) => item == "");

        var iName = 0;
        for (var name in names as Iterable<String>) {
          nameStart.add(line.indexOf(name));
          if (iName > 0) {
            nameEnd.add(nameStart[iName]);
          }
          iName += 1;
        }
        nameEnd.add(line.length - 1);
        firstRow = false;
      } else {
        line += " " * 400; // Pad the line
        dictionarySection = line.substring(nameStart[0], nameEnd[0]).trim();
        dictionaryDirective = line.substring(nameStart[1], nameEnd[1]).toLowerCase().trim();
        dictionaryAttributes = line.substring(nameStart[2], line.length).toLowerCase().trim();

        var allowBlockValue = "No";

        final allowAnyAttribute = dictionaryDirective.contains("*");
        if (allowAnyAttribute) {
          dictionaryDirective = dictionaryDirective.replaceAll("*", "");
          dictionaryAttributes = "allowanydirective";
        }

        if (dictionaryDirective.endsWith("(b)")) {
          dictionaryDirective = dictionaryDirective.substring(0, dictionaryDirective.length - 3);
          allowBlockValue = "Yes";
        } else if (dictionaryDirective.endsWith("(ob)")) {
          dictionaryDirective = dictionaryDirective.substring(0, dictionaryDirective.length - 4);
          allowBlockValue = "Optional";
        }

        dictionaryDirective = dictionaryDirective.replaceAll("()", ""); // Allows for (*)

        dictionaryAttributes += ", allowblock(=$allowBlockValue)";
        dictionaryAttributes = dictionaryAttributes.trim();
        if (dictionaryAttributes.startsWith(",")) dictionaryAttributes = dictionaryAttributes.substring(1);

        if (dictionarySection.isNotEmpty) {
          // Section start row
          activeSectionName = dictionarySection;
          dictionary[activeSectionName] = {};
        } else if (dictionaryDirective.isNotEmpty) {
          // Directive row
          dictionary[activeSectionName]![dictionaryDirective] = {};
          for (var attr in dictionaryAttributes.split(",")) {
            attrName = attr.trim();
            attrValCodes = "";
            final iStart = attrName.indexOf("(");
            if (iStart > 0) {
              final iEnd = attrName.indexOf(")");
              if (iEnd > iStart) {
                // ValCodes in brackets found
                attrValCodes = attrName.substring(iStart + 1, iEnd).toLowerCase();
                attrName = attrName.substring(0, iStart);
              }
            }

            dictionary[activeSectionName]![dictionaryDirective]![attrName] = attrValCodes;
          }
        }
      }
    }
  }

  static String getSectionType(String sectionName1) {
    final sectionName = sectionName1.removeFrom("_");
    var sectionType = "";
    if (sectionName == "Config") {
      sectionType = "Config";
    } else if (sectionName == "Setup")
      sectionType = "Setup";
    else if (sectionName == "Database")
      sectionType = "Database";
    else if (sectionName == "AppMenu")
      sectionType = "AppMenu";
    else if (sectionName == "AutoExecute")
      sectionType = "Form";
    else if (sectionName == "FormAutoExecute")
      sectionType = "Form";
    else if (sectionName == "ReportAutoExecute")
      sectionType = "Report";
    else if (sectionName == "Components")
      sectionType = "Components";
    else if (sectionName == "ReadMe")
      sectionType = "ReadMe";
    else if (sectionName == "Scripts")
      sectionType = "Form"; // Scripts can use any Form directives
    else if (sectionName.endsWith("FormProcedure"))
      sectionType = "Form";
    else if (sectionName.endsWith("ReportProcedure"))
      sectionType = "Report";
    else if (sectionName.endsWith("Procedure"))
      sectionType = "Procedure";
    else if (sectionName.endsWith("SplitView"))
      sectionType = "SplitView";
    else if (sectionName.endsWith("List"))
      sectionType = "List";
    else if (sectionName.endsWith("Form"))
      sectionType = "Form";
    else if (sectionName.endsWith("Report")) sectionType = "Report";
    return sectionType;
  }

  // =============== validate(directive, sectionType, sectionName) ============================================
  static bool validate(EBDirective directive, String sectionType, String sectionName) {
    //print("==== Validate: $directive");
    // ---- Check that the action key is present
    if (!directive.containsKey("action")) {
      EBCompile.logError("EBDictionary error - Missing action key in '$directive' ***");
      return false;
    }
    final String? action = directive["action"].toLowerCase();

    // ---- Get the dictionary entry for the action - for the sectionType of from Common if not found and allowed
    Map<String, String?>? directiveValCodes;
    final allowCommon = ["List", "Form", "Report"].contains(sectionType);

    if (!dictionary.containsKey(sectionType)) {
      EBCompile.logError("Missing section in directive dictionary = '$sectionType' $directive $sectionName ***");
      return false;
    } else if (dictionary[sectionType]!.containsKey(action)) {
      directiveValCodes = dictionary[sectionType]![action];
    ///} else if (allowCommon && dictionary["Shared"]!.containsKey(action)) {
     /// directiveValCodes = dictionary["Shared"]![action];
    } else {
      EBCompile.logError("Invalid directive '$action' in '$sectionName' section ***");
      return false;
    }

    if (directiveValCodes!.containsKey("allowanydirective")) return true;
    // ---- Get the default attrName
    // (Temporary work-around = Enter the attribute name)
    String? defaultAttrName = "";
    final nFound = 0;
    if (directiveValCodes.isNotEmpty) {
      var position = 0;
      for (String? key in directiveValCodes.keys) {
        position += 1;
        if (directiveValCodes[key]!.contains("*")) {
          if (position == 1) {
            defaultAttrName = key;
          } else {
            EBCompile.logError("Invalid dictionary for $action - '*' can only be provided for the first attribute. * for '$key' ignored.");
          }
        }
      }
    }

    // --- Set defaults for missing attributes
    // --- Values are set as strings... converted to numeric and bool as required in subsequent logic
    for (final attr in directiveValCodes.keys.where((key) => directiveValCodes![key]!.contains("="))) {
      if (!directive.containsKey(attr)) {
        // Was a value provided in the directive?
        final iPt = directiveValCodes[attr]!.indexOf("=");
        final defaultVal = directiveValCodes[attr]!.substring(iPt + 1).trim();
        final remainingCodes = directiveValCodes[attr]!.substring(0, iPt).trim();
        directive[attr] = defaultVal;
      }
    }

    // ---- If style attribute provided, validate and copy style attributes if not override
    _transferStyleAttributes(directive);

    // ---- Validate attribute names and values
    String? attrName;
    String? valCodes;
    final keyList = List<String>.from(directive.keys); // Copy required due to modification of iterable
    for (final attrName1 in keyList) {
      if (attrName1.toLowerCase() == "allowanyattribute") return true;
      if (attrName1 == "action") continue;
      attrName = attrName1.toLowerCase(); // Copied since it can be changed.
      if (attrName == "dirnum") continue; // Ignore DirNum - added for editor source line tracing.

      if (!directiveValCodes.containsKey(attrName)) {
        // --- If attrName is invalid, check if it is a value that should be assigned to a default attribute name
        if (defaultAttrName!.isNotEmpty) {
          directive.remove(attrName);
          attrName = defaultAttrName;
          directive[attrName] = attrName1;
        } else {
          if (directive["action"] == "if") {
            // Convert to condition attribute
            directive["condition"] = "$attrName=${directive[attrName]}";
            attrName = "condition";
            continue;
          } else {
            EBCompile.logError("Invalid attribute '$attrName' in '$action' directives, in $sectionName section.");
            print(directive);
            return false;
          }
        }
      }
      valCodes = directiveValCodes[attrName];

      // --- Remove "r"  (Required),  "*"  (Default) and "=exp" (default) text
      valCodes = valCodes!.replaceAll("r", ""); // Remove "r" (Required) code - processed after all attributes
      valCodes = valCodes.replaceAll("*", ""); // Remove "*" (Default attribute) code - processed after all attributes
      final iPt2 = valCodes.indexOf("=");
      if (iPt2 > -1) {
        valCodes = valCodes.substring(0, iPt2);
      }
      valCodes = valCodes.replaceAll(" ", "").trim();

      //--- Validations based on dictionary code
      String? attrValue = directive[attrName];

      if (valCodes.length > 1) {
        print("** Invalid dictionary entry for $action-$attrName = '$valCodes'. Should be a single character.");
        return false;
      }

      if (attrValue == null) {
        if (valCodes == "l") {
          // Logical attributes have default of true
          directive[attrName] = true;
          continue;
        }
      }

      if (valCodes.isNotEmpty) {
        switch (valCodes) {
          case "n": // Numeric
            if (attrValue!.toLowerCase() == "#memoheight#" ||
                attrValue.toLowerCase() == "#memoreportheight#" ||
                attrValue.toLowerCase() == "#imageheight#" ||
                attrValue.toLowerCase() == "#imageleft#" ||
                attrValue.toLowerCase() == "#imagebottom#") {
              directive[attrName] = attrValue;
            } else if ((attrName == "untilwithin" || attrName == "within") && attrValue.contains("#")) {
              // <Repeat untilWithin  and  StartNewPage within accept and #define# var
              directive[attrName] = attrValue;
            } else if (!isNumeric(attrValue) && !isFloat(attrValue)) {
              EBCompile.logError("Invalid value '$attrValue' for '$attrName' - Must be numeric");
              return false;
            } else {
              directive[attrName] = double.parse(attrValue);
            }
            break;

          case "l": // Logic - Yes or No

            attrValue = attrValue!.toLowerCase();
            if (!["yes", "no", "true", "false", "on", "off"].contains(attrValue)) {
              EBCompile.logError("Invalid value '$attrValue' for '$attrName' - Must be Yes, No, True, False, On or Off");
              return false;
            } else {
              directive[attrName] = attrValue == "yes" || attrValue == "true" || attrValue == "on";
            }
            break;

          case "c": // Database collection name
            // if (!validCollectionNames.contains(attrValue)) {
            //   errorMessages += "    *** Invalid attribute value = '$attrValue' - Must be a collection name ***\n";
            //   EBCompile.logError("Invalid attribute value = '$attrValue' - Must be a collection name ***");
            //   print("Valid collections = $validCollectionNames");
            // }
            break;

          case "f": // Field name - fieldName,  collection.fieldName  or form.fieldName
            // FieldNames in the format collectionRef.fieldname are validated.
            // Validation is only done if the collectionRef matches a collection.
            // Other strings with a "." are allowed, with the result that a mispelled collectionRef is not reported as an error.
            //   int iPt = attrValue.indexOf(".");
            //   if (iPt > -1) {
            //     String thisRef = attrValue.substring(0, iPt).toLowerCase();
            //     String thisFieldName = attrValue.substring(iPt+1).toLowerCase();
            //
            //     for (String collectionName in EBTemplate.validFieldNames.keys) {
            //       if (thisRef + "s" == collectionName.toLowerCase()) {
            //         // The reference is to a collection
            //         bool found = false;
            //         for (String fldName in EBTemplate.validFieldNames[collectionName]) {
            //           if (thisFieldName == fldName.toLowerCase()) {
            //             found = true;
            //             break;
            //           }
            //         }
            //         if (!found) errMsg = "Invalid field Name '$attrValue' for '$attrName' attribute";
            //       }
            //     }
            //   }
            break;

          default:
            if (valCodes.isNotEmpty) {
              print("** Invalid dictionary validation code for '$action-$attrName' in $sectionName-$action directive = '$valCodes'");
              return false;
            }
        }
      }

      //--- Validations based on attribute name
      if (attrName.endsWith("color") && !attrValue!.contains("/") && !attrValue.contains(".")) {
        if (!colorList.contains(attrValue.toLowerCase()) && !attrValue.startsWith("#") && !attrValue.startsWith("?")) {
          if (attrValue.split(".").length != 3) {
            EBCompile.logError("Invalid color '$attrValue' in $sectionName-$action. Must be $colorList ***");
            return false;
          }
        } else {
          directive[attrName] = attrValue.toLowerCase();
        }
      }

      if (attrName == "fontname") {
        if (!fontNameList.contains(attrValue!.toLowerCase())) {
          EBCompile.logError("Invalid fontName '$attrValue' in $sectionName-$action. Must be $fontNameList ***");
          return false;
        }
      }

      if (attrName == "align") {
        if (!["left", "center", "right", "justify", "top", "bottom"].contains(attrValue!.toLowerCase())) {
          EBCompile.logError("Invalid align = '$attrValue' in $sectionName-$action.  Must be Left, Center, Right, Justify, Top or Bottom ***");
          return false;
        } else {
          directive[attrName] = attrValue.toLowerCase();
        }
      }
    }

    // ---- Check for required attributes
    var reqdError = false;
    for (String? attr in directiveValCodes.keys.where((key) => directiveValCodes![key]!.contains("r"))) {
      if (directiveValCodes[attr]!.contains("r")) {
        if (!directive.containsKey(attr)) {
          EBCompile.logError("Missing required attribute '$attr' in $sectionName-$action directive directive=$directive  attr=$attr");
          reqdError = true;
        }
      }
    }
    if (reqdError) return false;
    return true;
  }

  // ============== _transferStyleAttributes ===========================================================
  static void _transferStyleAttributes(EBDirective dir) {
    // This method transfers style attributes into the current directive if they are not overridden
    if (!dir.keys.contains("style")) return;
    final String? origStyleName = dir["style"]; // Style name with case for error message
    final String? styleName = dir["style"].toLowerCase();
    if (dir["action"] == "drawtext" || dir["action"] == "drawpagenumber") {
      if (!EBCompile.textStyles.containsKey(styleName) && !EBCompile.labelStyles.containsKey(styleName)) {
        EBCompile.logError("Invalid text style '$origStyleName'");
      } else {
        final EBDirective textStyle = EBCompile.textStyles[styleName];

        for (var attr in textStyle.keys) {
          if (!dir.containsKey(attr)) {
            dir[attr] = textStyle[attr].toString();
          }
        }
      }
    } else if (["drawmemo", "drawtabbedmemo", "setmemoheight"].contains(dir["action"])) {
      Map<String, dynamic> memoStyle;
      if (!EBCompile.memoStyles.containsKey(styleName)) {
        if (EBCompile.textStyles.containsKey(styleName)) {
          memoStyle = EBCompile.textStyles[styleName];
        } else {
          EBCompile.logError("Invalid memo style '$origStyleName'");
          return;
        }
      } else {
        memoStyle = EBCompile.memoStyles[styleName];
      }

      for (var attr in memoStyle.keys) {
        if (!dir.containsKey(attr)) {
          dir[attr] = memoStyle[attr].toString();
        }
      }
    } else if (dir["action"].startsWith("drawline")) {
      if (!EBCompile.lineStyles.containsKey(styleName)) {
        EBCompile.logError("Invalid line style '$origStyleName'");
      } else {
        final EBDirective lineStyle = EBCompile.lineStyles[styleName];
        for (var attr in lineStyle.keys) {
          if (!dir.containsKey(attr)) dir[attr] = lineStyle[attr].toString();
        }
      }
    } else if (["drawbox", "drawrect", "drawcircle", "drawpolygon"].contains(dir["action"])) {
      if (!EBCompile.fillStyles.containsKey(styleName)) {
        EBCompile.logError("Invalid fill style '$origStyleName'");
      } else {
        final EBDirective fillStyle = EBCompile.fillStyles[styleName];
        for (var attr in fillStyle.keys) {
          if (!dir.containsKey(attr)) dir[attr] = fillStyle[attr].toString();
        }
      }
    } else if (dir["action"] == "drawarrow") {
      if (!EBCompile.arrowStyles.containsKey(styleName)) {
        EBCompile.logError("Invalid arrow style '$origStyleName'");
      } else {
        final EBDirective arrowStyle = EBCompile.arrowStyles[styleName];
        for (var attr in arrowStyle.keys) {
          if (!dir.containsKey(attr)) dir[attr] = arrowStyle[attr].toString();
        }
      }
    } else if (dir["action"] == "drawphotolocn" || dir["action"] == "drawphotolocns") {
      if (!EBCompile.photoLocnStyles.containsKey(styleName)) {
        EBCompile.logError("Invalid photoLocn style '$origStyleName'");
      } else {
        final EBDirective photoLocnStyle = EBCompile.photoLocnStyles[styleName];
        for (var attr in photoLocnStyle.keys) {
          if (!dir.containsKey(attr)) dir[attr] = photoLocnStyle[attr].toString();
        }
      }
    } else if (dir["action"] == "drawlabel") {
      if (!EBCompile.labelStyles.containsKey(styleName!.toLowerCase())) {
        EBCompile.logError("Invalid drawLabel style '$origStyleName'");
      } else {
        final EBDirective labelStyle = EBCompile.labelStyles[styleName];
        for (var attr in labelStyle.keys) {
          if (!dir.containsKey(attr)) dir[attr] = labelStyle[attr].toString();
        }
      }
    } else if (dir["action"] == "progressmessage") {
      if (!EBCompile.labelStyles.containsKey(styleName!.toLowerCase())) {
        EBCompile.logError("Invalid progressMessage style '$origStyleName'");
      } else {
        final EBDirective labelStyle = EBCompile.labelStyles[styleName];
        for (var attr in labelStyle.keys) {
          if (!dir.containsKey(attr)) dir[attr] = labelStyle[attr].toString();
        }
      }
    } else if (dir["action"] == "drawtextbox") {
      if (!EBCompile.controlStyles.containsKey(styleName!.toLowerCase())) {
        EBCompile.logError("Invalid drawTextBox style '$origStyleName'");
      } else {
        final EBDirective controlStyle = EBCompile.controlStyles[styleName];
        for (var attr in controlStyle.keys) {
          if (!dir.containsKey(attr)) dir[attr] = controlStyle[attr].toString();
        }
      }
    } else {
      EBCompile.logError("Invalid directive (in style attribute transfer) = '${dir["action"]}'");
    }
  }

// ============= list method ======================================================================
  void list({String? sectionName, String? directiveName}) {
    if (dictionary.isEmpty) {
      EBCompile.logError("Error from EBDictionary.list - dictionary is empty.");
      return;
    }

    if (sectionName != null && directiveName != null) {
      var msg = "\nDIRECTIVE DICTIONARY FOR $sectionName-$directiveName\n";
      for (var section in dictionary.keys) {
        if (section.toLowerCase() != sectionName.toLowerCase()) continue;

        for (String? dir in dictionary[section]!.keys) {
          if (dir!.toLowerCase() != directiveName.toLowerCase()) continue;

          for (String? attr in dictionary[section]![dir]!.keys) {
            msg += "-- ${dictionary[section]![dir]}\n";
            if (msg.length > 900) {
              print(msg);
              msg = "\n";
            }
          }
        }
      }
      print(msg);
    } else {
      var msg = "\nDIRECTIVE DICTIONARY:\n";
      for (var section in dictionary.keys) {
        msg += "== SECTION: $section\n";

        for (String? dir in dictionary[section]!.keys) {
          msg += "\n-- $dir:\n";

          for (String? attr in dictionary[section]![dir]!.keys) {
            msg += "      ${attr!.padTo(15)} ${dictionary[section]![dir]}\n";
            if (msg.length > 900) {
              print(msg);
              msg = "\n";
            }
          }
        }
      }
      print(msg);
    }
  }

  static Future<void> compileHelpDictionary(String dictionaryContents, Function m) async {
    dictionaryContents = dictionaryContents.removeComments();
    final List<String> dictionaryLines = dictionaryContents.split("\n");

    final nameStart = []; // List of column starts
    final nameEnd = []; // List of column ends
    var firstRow = true;
    String dictionarySection;
    String? dictionaryDirective;
    String dictionaryAttributes;
    var activeSectionName = "";
    String attrName;
    String attrValCodes;
    dictionary = {};
    String sectionID = "";
    String directiveID = "";
    String attrID = "";
    final fsSections = FirebaseFirestore.instance.collection("appData").doc("editorHelp").collection("sections");
    final fsDirectives = FirebaseFirestore.instance.collection("appData").doc("editorHelp").collection("directives");
    final fsAttributes = FirebaseFirestore.instance.collection("appData").doc("editorHelp").collection("attributes");

    for (var line in dictionaryLines as Iterable<String>) {
      if (line.trim().isEmpty) continue;
      if (line.trim().startsWith("//")) continue;
      m("===== $line");
      if (line.toLowerCase().trimLeft().startsWith("#define ")) {
        line = line.trim();
        final iPt = line.indexOf("=");

        if (iPt == -1) {
          EBCompile.logError("DICTIONARY ERROR - Missing '=' in #define '$line");
        } else {
          final varName = line.substring(8, iPt).toLowerCase().trim();
          final List<String> varValues = line.substring(iPt + 1).trim().split(",");

          if (varName == "fontnames") {
            fontNameList = [];
            for (var font in varValues as Iterable<String>) {
              fontNameList.add(font.trim().toLowerCase());
            }
          } else if (varName == "colors") {
            colorList = [];
            for (var color in varValues as Iterable<String>) {
              colorList.add(color.trim().toLowerCase());
            }
          } else {
            EBCompile.logError("DICTIONARY ERROR - INVALID Define = '$dictionaryDirective  (must be fontNames or Colors)");
          }
        }
        continue;
      }

      if (firstRow) {
        // Set the column positions from the first row
        final List<String> names = line.split(" ");
        names.removeWhere((item) => item == "");

        var iName = 0;
        for (var name in names as Iterable<String>) {
          nameStart.add(line.indexOf(name));
          if (iName > 0) {
            nameEnd.add(nameStart[iName]);
          }
          iName += 1;
        }
        nameEnd.add(line.length - 1);
        firstRow = false;
      } else {
        line += " " * 400; // Pad the line
        dictionarySection = line.substring(nameStart[0], nameEnd[0]).trim();
        dictionaryDirective = line.substring(nameStart[1], nameEnd[1]).trim();
        dictionaryAttributes = line.substring(nameStart[2], line.length).trim();

        var allowBlockValue = "No";

        final allowAnyAttribute = dictionaryDirective.contains("*");
        if (allowAnyAttribute) {
          dictionaryDirective = dictionaryDirective.replaceAll("*", "");
          dictionaryAttributes = "allowanydirective";
        }

        if (dictionaryDirective.endsWith("(b)")) {
          dictionaryDirective = dictionaryDirective.substring(0, dictionaryDirective.length - 3);
          allowBlockValue = "Yes";
        } else if (dictionaryDirective.endsWith("(ob)")) {
          dictionaryDirective = dictionaryDirective.substring(0, dictionaryDirective.length - 4);
          allowBlockValue = "Optional";
        }
        m("-- $dictionaryDirective");
        directiveID = EBUtil.generateKey();
        final Map<String, String> dirDoc = {
          "DirectiveID": directiveID,
          "SectionID": sectionID,
          "SectionName": activeSectionName,
          "DirectiveName": dictionaryDirective
        };
        await fsDirectives.doc(directiveID).set(dirDoc);

        dictionaryDirective = dictionaryDirective.replaceAll("()", ""); // Allows for (*)

        dictionaryAttributes += ", allowblock(=$allowBlockValue)";
        dictionaryAttributes = dictionaryAttributes.trim();
        if (dictionaryAttributes.startsWith(",")) dictionaryAttributes = dictionaryAttributes.substring(1);

        if (dictionarySection.isNotEmpty) {
          // Section start row
          activeSectionName = dictionarySection;
          dictionary[activeSectionName] = {};
          m("- $activeSectionName");
          sectionID = EBUtil.generateKey();
          final Map<String, String> sectionDoc = {"SectionID": sectionID, "SectionName": activeSectionName};
          await fsSections.doc(sectionID).set(sectionDoc);
        } else if (dictionaryDirective.isNotEmpty) {
          // Directive row
          dictionary[activeSectionName]![dictionaryDirective] = {};
          for (var attr in dictionaryAttributes.split(",")) {
            attrName = attr.trim();
            attrValCodes = "";
            final iStart = attrName.indexOf("(");
            if (iStart > 0) {
              final iEnd = attrName.indexOf(")");
              if (iEnd > iStart) {
                // ValCodes in brackets found
                attrValCodes = attrName.substring(iStart + 1, iEnd).toLowerCase();
                attrName = attrName.substring(0, iStart);
              }
            }

            dictionary[activeSectionName]![dictionaryDirective]![attrName] = attrValCodes;
            m("--- $attrName");
            attrID = EBUtil.generateKey();
            final Map<String, String> attrDoc = {
              "AttributeID": attrID,
              "DirectiveID": directiveID,
              "SectionName": activeSectionName,
              "DirectiveName": dictionaryDirective,
              "AttrName": attrName,
              "AttrCodes": attrValCodes
            };
            await fsAttributes.doc(attrID).set(attrDoc);
          }
        }
      }
    }
  }
}
