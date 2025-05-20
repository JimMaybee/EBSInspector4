// @formatter:off

import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';

import '../../../extensions.dart';

// For compatibility with flutter web.

// TODO: splitAndTrim(",")  - Ignore ending comma
// TODO: formatListOptionsForDisplay - ["a", "b", "c"] -->  "a, b or c"
// TODO: expandRanges  - "1, 2, 4-10, a, c" --> [1, 2, 4, 5, 6, 7, 8, 9, 10, "a", "c"]

class EBUtil {
  static String removeLastCharacter(String s) {
    final result = s.trim();
    return result.substring(0, result.length - 1);
  }

  // ========================= loadFileIntoSections(filename) =====================================================
  // - Loads a file for assets, removes comments and blank lines, and splits into sections.
  // - Used by EBDatabase.loadAppData and EBCompile

  static Future<Map<String, String?>> loadFileIntoSections(String filename) async {
    final content = await rootBundle.loadString("assets/testdata/$filename");
    return sectionsFromString(content);
  }

  static Map<String, String?> sectionsFromString(String content) {
    var inSection = false;
    String? sectionName;
    String? sectionContents;
    final result = <String, String?>{};

    final lines = content.removeComments().split("\n");
    // Split can leave a blank line at end
    if (lines[lines.length - 1].trim().isEmpty) lines.removeLast();

    for (var line in lines) {
      if (!inSection) {
        line = line.trim();
        sectionName = line.substring(1, line.length - 1);
        inSection = true;
        sectionContents = "";
      } else if (line.trim() == "</${sectionName!}>") {
        inSection = false;
        result[sectionName] = sectionContents;
      } else {
        sectionContents = "${sectionContents!}$line\n";
      }
    }
    return result;
  }

  // ======================== loadFileAndRemoveComments(fn) ==================================
  static Future<String> loadFileAndRemoveComments(String filename) async {
    final template = await rootBundle.loadString(filename);
    if (template.isEmpty) {
      return "";
    }

    return template.removeComments();
  }

  static Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  static Color? cvtColor(String c, double? opacity) {
    final List<String> parts = c.split(".");
    if (parts.length == 3) {
      return Color.fromARGB((255.0 * opacity!).toInt(), int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } else {
      switch (c.toLowerCase()) {
        case "clear":
          return null;
        case "black":
          return Colors.black.withValues(alpha: opacity!);
        case "white":
          return Colors.white.withValues(alpha: opacity!);
        case "gray":
          return Colors.grey.withValues(alpha: opacity!);
        case "lightgray":
          return Color.fromARGB(255, 220, 220, 220);
        case "red":
          return Colors.red.withValues(alpha: opacity!);
        case "green":
          return Colors.green.withValues(alpha: opacity!);
        case "lightgreen":
          return Color.fromARGB(255, 51, 255, 51);
        case "blue":
          return Colors.blue.withValues(alpha: opacity!);
        case "yellow":
          return Colors.yellow.withValues(alpha: opacity!);
        case "brown":
          return Colors.brown.withValues(alpha: opacity!);
        case "purple":
          return Colors.purple.withValues(alpha: opacity!);
        case "orange":
          //return Color.fromARGB(255, 255, 178, 102);
          return Colors.orange.withValues(alpha: opacity!);
        default:
          return Colors.black;
      }
    }
  }

  static PdfColor? cvtPDFColor(String? c, double? opacity) {
    PdfColor color;
    if (c == null) return PdfColors.black;
    final List<String> parts = c.split(".");

    if (parts.length == 3) {
      return PdfColor(double.parse(parts[0]) / 255.0, double.parse(parts[1]) / 255.0, double.parse(parts[2]) / 255.0, opacity!);
    } else {
      switch (c.toLowerCase()) {
        case "clear":
          return null;
        case "black":
          color = PdfColors.black;
          break;
        case "white":
          color = PdfColors.white;
          break;
        case "gray":
          color = PdfColors.grey;
          break;
        case "lightgray":
          color = PdfColors.grey;
          break;
        case "red":
          color = PdfColors.red;
          break;
        case "green":
          color = PdfColors.green;
          break;
        case "blue":
          color = PdfColors.blue;
          break;
        case "yellow":
          color = PdfColors.yellow;
          break;
        case "brown":
          color = PdfColors.brown;
          break;
        case "purple":
          color = PdfColors.purple;
          break;
        case "orange":
          color = PdfColors.orange;
          break;
        default:
          return PdfColors.black;
      }
      return PdfColor(color.red, color.green, color.blue, opacity!);
    }
  }

  static String generateKey() {
    final chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
    var s = "";
    final r = Random();
    for (var i = 0; i < 10; i++) {
      s += chars[r.nextInt(chars.length - 1)];
    }
    return s;
  }
}
