import 'dart:core';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:validators/validators.dart';

import 'EBClasses/Compiler/EBTypes.dart';


extension StringExtensions on String {

  String padTo(int n) {
    String result;
    if (length > n) {
      return this;
    } else {
      return (this + " " * n).substring(0, n);
    }
  }

  String removeFirst() {
    return substring(1);
  }

  String removeLast() {
    final result = trim();
    return result.substring(0, result.length - 1);
  }

  String removeFrom(s) {
    final iPt = indexOf(s);
    if (iPt == -1) return this;
    return substring(0, iPt);
  }

  String extractFrom(s) {
    final iPt = indexOf(s);
    if (iPt == -1) return this;
    return substring(iPt);
  }

  String proper() {
    final result = trim().toLowerCase();
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  String replaceSpecialChars() {
    return replaceAll("%dqt", '"').replaceAll("%qt", "'");
  }

  String removeComments() {
    var result = "";
    for (var line in split("\n")) {
      if (line.trim().isEmpty) continue;
      if (line.trim().startsWith("//")) continue;

      final iPt = line.indexOf(" //");
      if (iPt > -1) line = line.substring(0, iPt + 1);
      result += "$line\n";
    }
    return result;
  }

  int indexOfNonQuotedCharacter(String charToFind) {
    var inQuotes = false;
    String? quoteChar;

    for (var idx = 0; idx < length; idx++) {
      if (inQuotes) {
        if (this[idx] == quoteChar) {
          inQuotes = false;
        }
      } else if (this[idx] == '"' || this[idx] == "'") {
        inQuotes = true;
        quoteChar = this[idx];
      } else {
        if (this[idx] == charToFind) {
          return idx;
        }
      }
    }
    return -1;
  }

  bool isHTML() {
    if (!this.contains("<") && !this.contains(">")) return true;
    final htmlRegExp = RegExp('<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlRegExp.hasMatch(this);
  }

  List<dynamic> expandRanges() {
    // "1, 2, 3-5, a, b" --> {1, 2, 3, 4, 5, "a", "b"}   Numeric ranges only are expanded
    final result = [];
    for (var v in split(",")) {
      v = v.trim();
      final iPt = v.indexOf("-");
      if (iPt > 0) {
        final startVal = v.substring(0, iPt);
        final endVal = v.substring(iPt + 1);
        if (isNumeric(startVal) && isNumeric(endVal)) {
          final iStart = int.parse(v.substring(0, iPt));
          final iEnd = int.parse(v.substring(iPt + 1));
          for (var idx = int.parse(startVal); idx <= int.parse(endVal); idx++) {
            result.add(idx.toString());
          }
        } else {
          // A "-" with non-numeric values is not expanded
          result.add(v);
        }
      } else {
        result.add(v);
      }
    }
    return result;
  }

  Future<String> getContents() async {
    return await rootBundle.loadString(this);
  }

  List<String> splitAndTrim() {
    final result = <String>[];
    for (var item in split(",")) {
      result.add(item.trim());
    }
    return result;
  }

  List<String> splitAndRemoveComments() {
    return [];
  }

  String sortableDate() {
    // Requires 3 date components, allowing for "/", "." or "," as separators.
    // Numeric month and day uses mm/dd/yyyy format  (month first).
    // Alpha months use the first 3 characters only.
    // Invalid dates are returned unchanged.
    // Examples:
    //   "1 2 2021",  "2   3   2021",  "3/4/2021",  "4.5.2021",  "6.6.20",  "4.5.2021",  "5,6,2021"
    //   "Jan 2 2021",  "Feb 3 2021",  " 3  Mar 2021",  "Jan 10, 2021"
    var s = trim();
    s = s.replaceAll("/", " ");
    s = s.replaceAll(".", " ");
    s = s.replaceAll(",", " ");
    s = s.replaceAll("-", " ");
    s = s.replaceAll("  ", " ");
    s = s.replaceAll("  ", " ");
    final List<String> parts = s.split(" ");
    if (parts.length != 3) return s;

    // Check for mm-dd-yyyy format
    if (isNumeric(parts[0]) && isNumeric(parts[1]) && isNumeric(parts[2])) {
      if (!parts[2].startsWith("20")) return s;
      return "${parts[2]}${parts[0]}${parts[1]}";
    }

    if (parts[2].length == 2) parts[2] = "20${parts[2]}";
    String yyyy = parts[2];
    if (yyyy.length == 2) yyyy = "20$yyyy";

    final months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
    String? mth, mm, dd;

    if (isNumeric(parts[0]) && isNumeric(parts[1])) {
      mm = parts[0];
      dd = parts[1];
      if (int.parse(mm) > 12) {
        final save = mm;
        mm = dd;
        dd = save;
      }
    } else if (!isNumeric(parts[0]) && isNumeric(parts[1])) {
      mth = "${parts[0]}   ".substring(0, 3);
      mm = (months.indexOf(mth.toLowerCase()) + 1).toString();
      dd = parts[1];
    } else if (isNumeric(parts[0]) && !isNumeric(parts[1])) {
      mth = "${parts[1]}   ".substring(0, 3);
      mm = (months.indexOf(mth.toLowerCase()) + 1).toString();
      dd = parts[0];
    } else {
      return s;
    }

    if (mm == "-1") return s;
    mm = mm.padLeft(2, "0");
    dd = dd.padLeft(2, "0");
    return "$yyyy.$mm.$dd";
  }



  int leadingDigits() {
    var digits = "0";
    for (var i = 0; i < length; i++) {
      if (this[i] == " ") continue;
      if (this[i] == ".") break;
      if (isNumeric(this[i])) {
        digits += this[i];
      } else {
        break;
      }
    }
    return int.parse(digits);
  }

  String sortAreaCode() {
    debugPrint("===== Sort $this");
    final String part1 = split(".")[0];
    String part2 = "";
    if (this.contains(".")) {
      part2 = split(".")[1];
    }
    return "${part1.padLeft(4, "0")}.${part2.padLeft(4, "0")}";
  }

  String padNumeric() {
    // "12xxx" -->  "0012xxx"
    var nVal = 0;
    var prefixLength = 0;
    for (var nChar = 0; nChar < min(length, 5); nChar++) {
      if (!isNumeric(this[nChar])) break;
      nVal = nVal * 10 + int.parse(this[nChar]);
      prefixLength += 1;
    }
    return nVal.toString().padLeft(4, "0") + substring(prefixLength);
  }

  List<Map<String, String>> toCollectionRows() {
    bool firstLine;
    List<String> names = []; // Column (field) names
    List<int> nameStart = []; // Column start positions
    List<int> nameEnd = []; // Column end positions
    List<String> sectionLines;
    final result = <Map<String, String>>[];

    firstLine = true;
    for (var line in split("\n")) {
      if (line.trim().isEmpty) continue;
      if (line.trim().startsWith("//")) continue;
      if (firstLine) {
        // --- First non-comment row contains field names
        firstLine = false;
        names = [];
        nameStart = [];
        nameEnd = [];

        names = line.split(" ");
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
      } else {
        // --- Data row - add to result
        line += " " * 100;
        String value;
        final row = <String, String>{};
        for (var j = 0; j < names.length; j++) {
          if (j == names.length - 1) nameEnd[j] = line.length;
          value = line.substring(nameStart[j], nameEnd[j]).trim();
          row[names[j]] = value;
        }
        result.add(row);
      }
    }
    return result;
  }


}

extension ListExtensions on EBDirectives {
  String compiledDirectiveAsString(String hdg) {
    //
    // Formats a string for compiled directives display (list of maps):
    //   {"action": "drawText", "at": 1, "data":"Project Name"}, {"action": "moveDown", "at": 4, "data":"Client name"}
    //   -->
    //   Hdg:
    //     drawText at:1, data:'Project Name'
    //     drawText at:4, data:'Client Name'
    //
    var result = "\n$hdg\n";
    for (var i = 0; i < length; i++) {
      result += "  ${this[i]["action"]} ";
      var first = true;
      for (var key in this[i].keys) {
        if (key == "action") continue;
        if (!first) result += ", ";
        first = false;
        result += "$key: ";
        var val = this[i][key].toString();
        if (!isNumeric(val) && val != "true" && val != "false") val = "'$val'";
        result += val;
      }
      result += "\n";
    }
    return result;
  }

  EBDirectives sortByProperty(String propertyName) {
    for (var row in this) {
      if (!row.containsKey(propertyName)) row[propertyName] = "";
    }

    if (propertyName.toLowerCase().endsWith("date")) {
      return this..sort((a, b) => (a[propertyName].toUpperCase().toString().sortableDate()).compareTo(b[propertyName].toUpperCase().toString().sortableDate()));
    } else if (propertyName.toLowerCase().endsWith("number")) {
      return this..sort((a, b) => (a[propertyName].toUpperCase().toString().padNumeric()).compareTo(b[propertyName].toUpperCase().toString().padNumeric()));
    } else {
      return this..sort((a, b) => (a[propertyName].toUpperCase()).compareTo(b[propertyName].toUpperCase()));
    }
  }

  EBDirectives sortByPropertyDesc(String propertyName) {
    // Sort descending
    //for (var row in this as Iterable<Map<String, String>>) {
    for (var row in this) {
      if (!row.containsKey(propertyName)) row[propertyName] = "";
    }

    //return this..sort((a, b) => (b[sortPropertyName].toUpperCase()).compareTo(a[sortPropertyName].toUpperCase()));
    if (propertyName.toLowerCase().endsWith("date")) {
      return this..sort((a, b) => (b[propertyName].toUpperCase().toString().sortableDate()).compareTo(a[propertyName].toUpperCase().toString().sortableDate()));
    } else if (propertyName.toLowerCase().endsWith("number")) {
      return this..sort((a, b) => (b[propertyName].toUpperCase().toString().padNumeric()).compareTo(a[propertyName].toUpperCase().toString().padNumeric()));
    } else {
      return this..sort((a, b) => (b[propertyName].toUpperCase()).compareTo(a[propertyName].toUpperCase()));
    }
  }

  List<dynamic> sortByPropertyText(String propertyName) {
    // Sort on Text string
    //for (var row in this as Iterable<Map<String, String>>) {
    for (var row in this) {
      if (!row.containsKey(propertyName)) row[propertyName] = "";
    }

    return this..sort((a, b) => (a[propertyName].toUpperCase()).compareTo(b[propertyName].toUpperCase()));
  }

  String getPrice(String x) {
    return x.substring(2);
  }

  String displayFormat(String fields) {
    var result = "";
    var n = 0;
    for (var element in this as Iterable<EBDirective>) {
      result += "$n: ";
      if (fields.isNotEmpty) {
        result += "{";
        var comma = "";
        for (var fld in fields.split(",")) {
          if (element.containsKey(fld)) {
            result += "$comma$fld: ${element[fld].toString()}";
            comma = ", ";
          }
        }
        result += "}\n";
      } else {
        result += "${element.toString()}\n";
      }
      n += 1;
    }
    return result;
  }
}


extension DoubleExtensions on double {
  String twoDecimals() {
    return toStringAsFixed(2);
  }
}
