import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

Map<String, String> extractVerses(String htmlContent) {
  String htmlContentOriginal = htmlContent;
  final document = html_parser.parse(htmlContent);
  final Map<String, String> verses =
      {}; // Change key type to String to handle non-integer verse numbers

  String currentVerseNumber = "";
  StringBuffer currentVerseText = StringBuffer();

  void flushCurrentVerse() {
    //print("flushCurrentVerse, number: $currentVerseNumber text:$currentVerseText");
    if (currentVerseNumber != "") {
      final text = currentVerseText
          .toString()
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'(?<!<br>)(<br>)$'), '');
      verses[currentVerseNumber] = text;
    } else if (currentVerseText
        .toString()
        .contains('<span class="red-text">℟</span>')) {
      final text =
          currentVerseText.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
      verses[" "] = "$text  <br> <br>";
    }
    currentVerseNumber = "";
    currentVerseText = StringBuffer();
  }

  try {
    // If there is no mention of vers number in the html content,
    // return the content as a single string
    if (!htmlContentOriginal.contains("verse_number")) {
      //print("extractVerses verses: no verse_number at all, returning htmlContentOriginal");
      return {"": htmlContentOriginal};
    }

    for (var node in document.body!.nodes) {
      if (node.nodeType == html_dom.Node.ELEMENT_NODE) {
        final element = node as html_dom.Element;

        for (var child in element.nodes) {
          if (child.nodeType == html_dom.Node.ELEMENT_NODE) {
            final childElement = child as html_dom.Element;
            if (childElement.classes.contains('verse_number')) {
              flushCurrentVerse();
              //print("currentVerseNumber: ${childElement.text.trim()}");
              currentVerseNumber = childElement.text.trim(); // Store as String
            } else {
              currentVerseText.write(childElement.outerHtml);
              //print("childElement.outerHtml Add1: ${childElement.outerHtml}");
            }
          } else if (child.nodeType == html_dom.Node.TEXT_NODE) {
            currentVerseText.write(child.text);
            //print("child.text Add2: ${child.text}");
          }
        }
        flushCurrentVerse();
      }
    }

    // If no verse numbers are found, return the content as a single string
    if (verses.isEmpty) {
      //print("extractVerses verses: isEmpty, returning htmlContentOriginal");
      return {"": htmlContentOriginal};
    }

    //print("extractVerses verses: $verses");
    return verses;
  } on Exception catch (e) {
    // print("extractVerses error: $e");
    return {"error": e.toString()};
  }
}
