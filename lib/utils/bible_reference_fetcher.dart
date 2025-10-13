import 'package:aelf_flutter/app_screens/book_screen.dart';
import 'package:aelf_flutter/utils/parse_chapter.dart';
import 'package:flutter/material.dart';
import 'text_management.dart';

void refButtonPressed(String references_element, BuildContext context) {
  print("references_element : $references_element");

  // The following part is derived from
  // https://github.com/HackMyChurch/aelf-dailyreadings/blob/5d59e8d7e5a7077b916971615e9c52013ebf8077/app/src/main/assets/js/lecture.js
  // which is available under the MIT licence
  // So we can use it in this AGPL open course project, but not change the licence
  // Thus here begins a MIT code block

  //   ----------------------
  // | Start of the MIT code |
  //   ----------------------

  // Extract reference-ish from a larger string
  // This allows surviving references like "Stabat Mater. Jn 19, 25-27"
  RegExp reference_extractor = RegExp(
      r'^(?<prefix>.*?)(?<reference>(?:[1-3]\s*)?[a-zA-Z]+\w*\s*[0-9]+(?:\s*\([0-9]+\))?(?:,(?:[-\s,.]|(?:[0-9]+[a-z]*))*[a-z0-9]\b)?)(?<suffix>.*?)$');

  // Extract reference
  //var reference_full_string = references_element.textContent.slice(1);
  String reference_full_string = references_element;
  Iterable<RegExpMatch> reference_parts =
      reference_extractor.allMatches(reference_full_string);
  if (reference_parts.isEmpty) {
    print("reference_parts is empty");
    return null;
  }

  // Extract reference components
  // ignore: unused_local_variable
  String reference_prefix = reference_parts.first[1] ?? "";
  String reference_text = reference_parts.first[2] ?? "";
  // ignore: unused_local_variable
  String reference_suffix = reference_parts.first[3] ?? "";

  // Prepare link
  String reference = reference_text;

  // Extract "Cantiques" references
  if (RegExp(r'^CANTIQUE').hasMatch(reference)) {
    reference = reference.split('(')[1].split(')')[0];
  }

  // Clean extracted reference
  reference = reference.toLowerCase();
  // Remove all type of whitespaces
  reference = reference.replaceAll(RegExp(r'\s*'), "");
  // Remove some stuffs around parentethis
  reference = reference.replaceAll(RegExp(r'\([0-9]*[A-Z]?\)'), "");

  // Do we still have something to parse ?
  if (reference == "") {
    return null;
  }

  // Extract the main reference chunks
  var matches = RegExp(r'([0-9]?)([a-z]+)([0-9]*[a-b]*)(,?)(.*?)(?:-[iv]+)*$')
      .allMatches(reference);
  if (matches.isEmpty) {
    return null;
  }

  String book_number = matches.first[1] ?? "";
  String book_name = capitalizeFirstLowerElse(matches.first[2]);
  String chapter = matches.first[3] ?? "";
  String comma = matches.first[4] ?? "";
  String rest = matches.first[5] ?? "";

  // Build the link
  String verses = chapter.toUpperCase() + comma + rest;
  print("verses = $verses");
  String link =
      "https://www.aelf.org/bible/$book_number$book_name/$chapter?reference=$verses";
  print("link = $link");

  //   -- -----------------
  // | End of the MIT code |
  //   -------------------

  Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExtractArgumentsScreen(
            bookNameShort: book_number + book_name,
            bookChToOpen: chapter,
            keywords: [""],
            reference: parse_reference(verses)),
      ));
}
