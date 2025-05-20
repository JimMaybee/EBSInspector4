// @formatter:off

import '../../extensions.dart';
import 'EBDictionary.dart';
///import 'EBPreprocess.dart';
import 'EBTypes.dart';

class EBCompile {
  static bool trace = false;
  static String directiveError = "";
  static String errorDirective = "";
  static List<String> compileErrors = [];
  static bool reportErrorLineNumbers = false;
  static int errorLineNumber = 0;
  static String blocksToCompile = "";
  static String breakPoint = "99999";
  static Map<String, EBDirectives> compiledTemplate = {};
 
  static void logError(msg) {
    final lineNumber = errorLineNumber == 0 ? "" : "$errorLineNumber: ";
    compileErrors.add("$lineNumber$errorDirective");
    compileErrors.add("---$msg");
    print("===== $lineNumber$errorDirective $msg");
  }

  static EBDirective controlStyles = {};
  static EBDirective labelStyles = {};
  static EBDirective textStyles = {};
  static EBDirective memoStyles = {};
  static EBDirective lineStyles = {};
  static EBDirective fillStyles = {};
  static EBDirective arrowStyles = {};
  static EBDirective photoLocnStyles = {};
  static String? templateSource = "";
  static Map<String, String> sectionSource = {};
  static String templateSourceWithComments = "";

  static void initialize() {}

  static Future<bool> compile(String templateSource) async {
    //debugPrint("========= compile\n$templateSource");
    // Add the Templates collection, menu item, splitView, list and form.

    final templateCollection = "<collection name=Templates     key=TemplateID     parent=''    keyPrefix=T  database=roofAsset/>";
    final templateAppMenu = "<menuItem  text=Templates    icon=TemplatesIcon.png   template=TemplateSplitView  onlineOnly/>";

    final templateSections = '''<TemplateSplitView>
    <DrawList  title="Templates"          template=TemplateList  allowAdd=Yes  allowEdit=No />
    <DrawForm  title="Template Details"   template=TemplateForm/>
</TemplateSplitView>

<TemplateList>
<Cell width=4>
    <DrawLabel label=Description bold fontSize=14 />
</Cell>
</TemplateList>

<TemplateForm>
    <MoveDown .3  />
    <DrawMemoControl at=.2 label="Notes:"  labelWidth=1 name=TemplateNotes width=8 height=10/> 
</TemplateForm>''';

    //templateSource = templateSource.replaceAll("<Database>", "<Database>\n$templateCollection");
    //templateSource = templateSource.replaceAll("<AppMenu>", "<AppMenu>\n$templateAppMenu");
    //templateSource = templateSource.replaceAll("</AppMenu>", "</AppMenu>\n$templateSections");
    // for (String line in templateSource.split("\n")) {
    //   print("--- $line");
    // }

    // Set styles defaults
    controlStyles = {};
    labelStyles = {
      "defaultlabelstyle": {
        "fontname": "helvetica",
        "fontsize": 18.0,
        "fontcolor": "Black",
        "backgroundcolor": "Clear",
        "align": "Left",
        "width": 0.0,
        "underline": false,
        "bold": true
      },
      "defaultlistcelllabelstyle": {
        "fontname": "arial",
        "fontsize": 16.0,
        "fontcolor": "Black",
        "backgroundcolor": "Clear",
        "align": "Left",
        "width": 0.0,
        "underline": false,
        "bold": false
      }
    };
    textStyles = {
      "defaultlabelstyle": {
        "fontname": "helvetica",
        "fontsize": 18.0,
        "fontcolor": "Black",
        "backgroundcolor": "Clear",
        "align": "Left",
        "width": 0.0,
        "underline": false,
        "bold": true
      },
      "defaulttextstyle": {
        "fontname": "helvetica",
        "fontsize": 14.0,
        "fontcolor": "Black",
        "backgroundcolor": "Clear",
        "align": "Left",
        "width": 0.0,
        "underline": false,
        "underlinewidth": false,
        "bold": false,
        "italic": false
      }
    };
    memoStyles = {
      "defaultmemostyle": {
        "fontname": "helvetica",
        "fontsize": 14.0,
        "fontcolor": "Black",
        "backgroundcolor": "Clear",
        "align": "Left",
        "underline": false,
        "bold": false,
        "italic": false
      }
    };
    lineStyles = {
      "defaultlinestyle": {"linewidth": 1.0, "linecolor": "black", "opacity": 1.0}
    };
    fillStyles = {
      "defaultfillstyle": {"linewidth": 1.0, "linecolor": "black", "fillcolor": "yellow", "opacity": .5}
    };
    arrowStyles = {
      "defaultarrowstyle": {
        "linewidth": 2.0,
        "linecolor": "Black",
        "fillcolor": "Black",
        "opacity": 1.0,
        "arrowlength": 20.0,
        "arrowindent": 6.0,
        "arrowwidth": 8.0
      }
    };
    photoLocnStyles = {
      "defaultphotolocnstyle": {
        "radius": 10.0,
        "linewidth": 2.0,
        "linecolor": "Black",
        "fillcolor": "Yellow",
        "opacity": 1.0,
        "fontsize": 12.0,
        "fontcolor": "Black",
        "directionindicators": true
      }
    };
    compileErrors = [];
    final compiledTemplate = <String, EBDirectives>{};
    String template;
    String directives;

    //templateSource = EBUtil.removeComments(templateSource);
    templateSourceWithComments = templateSource;
    // templateSource = EBPreprocess.selectReportBlocks(templateSource);
    templateSource = templateSource.removeComments();

    if (templateSource.isEmpty) {
      logError("Invalid templateSource argument to EBCompile.  length=0");
      return false;
    }

    ///templateSource = EBPreprocess.mergeIncludes(templateSource);
    ///templateSource = EBPreprocess.replaceGlobalVars(templateSource);
    final lines = templateSource.split("\n");
    if (lines[lines.length - 1].trim().isEmpty) lines.removeLast();

    var inSection = false;
    var sectionName = "";
    var sectionContents = "";

    for (var line in lines) {
      //debugPrint("--- $line");
      if (line.trim().isEmpty) continue; // The split leaves a blank lines at the end of the list.  Other blank lines have been removed.
      if (!inSection) {
        line = line.trim();
        sectionName = line.substring(1, line.length - 1);
        inSection = true;
        sectionContents = "";
      } else if (line.trim().startsWith("</$sectionName>")) {
        line = line.trim();
        inSection = false;
        final sectionType = EBDictionary.getSectionType(sectionName);
        if (sectionType != "Components" && sectionType != "ReadMe") {
          // The Components & ReadMe sections are not compiled.  It is used for #includes in other templates only.
          compiledTemplate[sectionName] = compileSection(sectionContents, sectionName, sectionType);
          EBCompile.sectionSource[sectionName] = sectionContents;
        }
      } else {
        if (line.trim().isNotEmpty) {
          sectionContents += "$line\n";
        }
      }
    }

    if (inSection) {
      logError("Missing section end '</$sectionName>' in template");
      return false;
    }

    // Save compiled template if no compile errors

    final errorsFound = compileErrors.isNotEmpty;
    if (!errorsFound) {
      // Update EBAppController source & compiled template
      EBCompile.templateSource = templateSourceWithComments;
      EBCompile.compiledTemplate = compiledTemplate;
    }

    return !errorsFound;
  }

  static EBDirectives compileSection(String sectionContent, String sectionName, String sectionType) {
    final sectionContentSave = sectionContent;
    var directiveNumber = 0;
    ///EBPreprocess.sectionName = sectionName;
    ///EBPreprocess.isForm = sectionName.toLowerCase().endsWith("form");
    ///EBPreprocess.isReport = sectionName.toLowerCase().endsWith("report");

    ///sectionContent = EBPreprocess.replaceVars(sectionContent);
    ///sectionContent = EBPreprocess.replaceDefineDirectives(sectionContent);
    ///sectionContent = EBPreprocess.preProcess(sectionContent);
    ///sectionContent = EBPreprocess.replaceVars(sectionContent);
    List<EBDirectives> blockDirectives; // Block directives are saved in List
    EBDirective thisCompiledDirective;

    var result = <EBDirective>[];
    String directive;
    int iStart, iEnd;
    int level; // Level for block directives  0-based.

    // Check for #endCompile directive and remove remaining if found
    var newContent = "";
    for (var line in sectionContent.split("\n")) {
      if (line.trim().toLowerCase().startsWith("#endcompile")) break;
      newContent += "$line\n";
    }

    sectionContent = newContent;
    blockDirectives = [[]];
    sectionContent = sectionContent.trim();
    iStart = sectionContent.indexOf("<");
    level = 0;

    reportErrorLineNumbers = false;
    errorLineNumber = 0;

    // Repeat for each directive
    while (iStart != -1) {
      if (iStart > 0) {
        if (sectionContent.toLowerCase().trim().startsWith("#starterrorlinenumbers")) {
          reportErrorLineNumbers = true;
          sectionContent = sectionContent.substring(iStart);
          iStart = 0;
          continue;
        }
        if (sectionContent.toLowerCase().trim().startsWith("#enderrorlinenumbers")) {
          reportErrorLineNumbers = false;
          errorLineNumber = 0;
          sectionContent = sectionContent.substring(iStart);
          iStart = 0;
          continue;
        }
        logError("Content found between directives = '${sectionContent.substring(0, iStart)} - Ignored ***");
      }

      sectionContent = sectionContent.substring(iStart);
      iEnd = sectionContent.substring(iStart).indexOfNonQuotedCharacter(">");
      if (iEnd == -1) {
        logError("Missing '>' in section $sectionName\n${sectionContent.substring(iStart)}\n$sectionContent");
        break;
      }
      if (iStart != -1) {
        // Check that there isn't a missing '>'  ('<' is before the next '>')
        final iEndCheck = sectionContent.substring(iStart).indexOfNonQuotedCharacter(">");
        if (iEndCheck != -1 && iEndCheck < iStart) {
          logError("Missing > in section '$sectionName");
          break;
        }
      }

      directive = sectionContent.substring(0, iEnd + 1).trim();
      if (sectionName == "ProjectForm") {
        //print("--- $directiveNumber $directive");
      }
      if (reportErrorLineNumbers) {
        errorLineNumber += 1;
      }

      thisCompiledDirective = compileDirective(directive, sectionName, sectionType);
      //debugPrint("========= $sectionName  $directive");
      //if (sectionName == "ProjectForm") {
      directiveNumber += 1;
      thisCompiledDirective["dirnum"] = directiveNumber;
      //}

      if (directive.startsWith("</") && directive.endsWith("/>")) {
        logError("Invalid directive $directive");
        break;
      }
      if (directive.startsWith("</")) {
        //--- Closing directive  </ ...>

        if (level == 0) {
          logError("Invalid block closing directive '$directive' - There is no opening directive");
          break;
        }

        // Add enclosed directives to previous level with key "directives"
        final lastIdx = blockDirectives[level - 1].length - 1;

        //String openingAction = blockDirectives[level - 1][lastIdx]["action"];
        //String closingAction = compiledDirective["action"];
        blockDirectives[level - 1][lastIdx]["directives"] = blockDirectives[level];
        blockDirectives.removeLast();
        //print("--- Closing ${blockDirectives[level]} \nadded to:\n ${blockDirectives[level-1]}  $lastIdx");
        level -= 1;

        //if (closingAction != openingAction) {
        //  print("***Block closing directive does not match opening directive '$openingAction'");
        //}
      } else if (directive.endsWith("/>")) {
        //---  Single-line directive  <... />

        // if (thisCompiledDirective["allowblock"] == "yes") {
        //   print("*** Directive must use block directive format, ending with '>':\n    $directive\n");
        //   return [];
        // }

        final String action = thisCompiledDirective["action"];
        if (action.endsWith("style")) {
          final String styleName = thisCompiledDirective["name"].toLowerCase();
          thisCompiledDirective.remove("action");
          thisCompiledDirective.remove("name");

          switch (action) {
            case "definecontrolstyle":
              // Not used
              //controlStyles[styleName] = thisCompiledDirective;
              break;

            case "definelabelstyle":
              labelStyles[styleName] = thisCompiledDirective;
              break;

            case "definetextstyle":
              textStyles[styleName] = thisCompiledDirective;
              break;

            case "definememostyle":
              memoStyles[styleName] = thisCompiledDirective;
              break;

            case "definelinestyle":
              lineStyles[styleName] = thisCompiledDirective;
              break;

            case "definefillstyle":
              fillStyles[styleName] = thisCompiledDirective;
              break;

            case "definephotolocnstyle":
              photoLocnStyles[styleName] = thisCompiledDirective;
              break;

            default:
              logError(
                  "Invalid directive $action - Expected defineControlStyle, defineLabelStyle, defineTextStyle, defineMemoStyle, defineLineStyle or defineFillStyle");
          }
        } else {
          blockDirectives[level].add(thisCompiledDirective);
        }
      } else {
        // Opening directive   <... >
        //print("--- Check if opening okay $thisCompiledDirective");
        // bool allowBlock = thisCompiledDirective["allowblock"] == "yes" || thisCompiledDirective["allowblock"] == "optional";
        // if (allowBlock) {
        blockDirectives[level].add(thisCompiledDirective);
        level += 1;
        blockDirectives.add([]);

        // } else {
        //   print("*** Directive does not support blocks:\n    $directive\n    $thisCompiledDirective");
        //   return [];
        // }
      }
      sectionContent = sectionContent.substring(iEnd + 1).trim(); // Remove current directive
      iStart = sectionContent.indexOf("<"); // Find next directive start
    }

    result = [];
    for (thisCompiledDirective in blockDirectives[0]) {
      result.add(thisCompiledDirective);
    }
    return result;
  }

  static EBDirective compileDirective(String directive, String sectionName, String sectionType) {
    //debugPrint("=== $sectionName $directive");
    final sv = directive;
    // Convert extended ASCII quotes to required quotes.
    directive = directive.replaceAll(String.fromCharCode(8216), "'");
    directive = directive.replaceAll(String.fromCharCode(8217), "'");
    directive = directive.replaceAll(String.fromCharCode(8220), '"');
    directive = directive.replaceAll(String.fromCharCode(8221), '"');

    EBDirective compiled;
    final trace = false;
    List<String> formNamesUsed;
    formNamesUsed = [];
    // The directive is "consumed" as it is processed.
    // The following 2 functions extract and remove parts of the directive
    //   _getString extracts and removes strings from directive - used for the directive name and attribute names
    //   _getValue extracts and removes attribute values from directive - enclosed in single quotes, double quotes or spaces

    String getString() {
      if (trace) print("=== _getString from '$directive'");
      // Extract up to next space, "=" or end of line
      var result = "";
      directive = directive.trim();
      while (directive.isNotEmpty) {
        if (directive[0] == " " || directive[0] == "=") break;
        result += directive[0];
        directive = directive.substring(1);
      }
      directive = directive.trim();
      if (trace) print("--- _getString result = '$result'");
      return result;
    }

    String getValue() {
      if (trace) print("=== _getValue from '$directive'");
      var result = "";
      directive = directive.trim();

      var endingCharacter = " ";
      var iPt = 0;
      if (directive.startsWith("'")) {
        endingCharacter = "'";
        iPt = 1;
      } else if (directive.startsWith('"')) {
        endingCharacter = '"';
        iPt = 1;
      }

      // Remove the opening quote and pad with a space to provide a terminating character if no quotes used
      directive = "${directive.substring(iPt)} ";

      // Get the value
      iPt = directive.indexOf(endingCharacter);
      if (iPt == -1) {
        logError("Invalid directive - Closing quote not found");
        result = "";
      } else {
        result = directive.substring(0, iPt);
        directive = directive.substring(iPt + 1).trim();
      }
      if (trace) print("--- _getValue result = $result");
      return result;
    }

    // ==== compileDirective logic ====================================================

    // ---- Check for enclosing <....>, <... /> or </....>  and remove
    directive = directive.trim();
    if (!directive.startsWith("<")) {
      logError("Invalid directive - must start with '<'");
      return {};
    }

    if (!directive.endsWith(">")) {
      logError("Invalid directive - must end with '>'");
      return {};
    }
    directive = directive.substring(1, directive.length - 1).trim();
    if (directive.startsWith("/")) directive = directive.substring(1);
    if (directive.endsWith("/")) directive = directive.substring(0, directive.length - 1);

    // ---- Extract the directive name and set as 'action'
    final action = getString().toLowerCase();
    compiled = {"action": action};

    // ---- Extract attribute and values
    // ---- If the value is missing it is set to null
    // ---- Validations and attrValue conversions are done in EBDictionary.validate()

    String attrName;
    String attrValue;

    while (directive.isNotEmpty) {
      attrName = getString().toLowerCase();
      var missingValue = false;
      if (directive.isEmpty) {
        missingValue = true;
      } else if (directive[0] != "=") {
        missingValue = true;
      }
      if (missingValue) {
        // If attrValue is missing, then it is set to null
        // EBDictionary.validate() will then either set a default value or attribute name, or detect an error
        compiled[attrName] = null;
        continue;
      }

      directive = directive.substring(1).trim(); // Remove the '='
      attrValue = getValue();
      // ---- Check for duplicate attrName
      if (compiled.keys.contains(attrName)) {
        logError("Warning - Duplicate attribute '$attrName' in $sectionName-$action - ignored ***");
      } else {
        compiled[attrName] = attrValue;
      }

      // ---- Check for duplicate form control names
      if (sectionType == "Form") {
        if (attrName == "name") {
          if (formNamesUsed.contains(attrValue.toLowerCase())) {
            logError("Warning - Duplicate form control name '$attrValue' found");
            continue;
          } else {
            formNamesUsed.add(attrValue);
          }
        }
      }
    }

    EBCompile.errorDirective = directive;
    EBDictionary.validate(compiled, sectionType, sectionName);
    return compiled;
  }
}
