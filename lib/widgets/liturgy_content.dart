import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

Map<String, String> extractVerses(String htmlContent) {
  String htmlContentOriginal = htmlContent;
  // Replace two or more <br /> with a single <br />
  // htmlContent =
  //    htmlContent.replaceAll(RegExp(r'(<br\s*/?>\s*){2,}'), 'br_placeholder');
  // Remove single <br />
  // htmlContent = htmlContent.replaceAll(RegExp(r'(<br\s*/?>)'), '');
  // Restore one <br /> for places where there were two or more
  // htmlContent = htmlContent.replaceAll('br_placeholder', '<br />');
  final document = html_parser.parse(htmlContent);
  final Map<String, String> verses =
      {}; // Change key type to String to handle non-integer verse numbers

  String? currentVerseNumber;
  StringBuffer currentVerseText = StringBuffer();

  void flushCurrentVerse() {
    if (currentVerseNumber != null) {
      final text =
          currentVerseText.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
      verses[currentVerseNumber] = text;
    }
    currentVerseText = StringBuffer();
  }

  try {
    for (var node in document.body!.nodes) {
      if (node.nodeType == html_dom.Node.ELEMENT_NODE) {
        final element = node as html_dom.Element;

        for (var child in element.nodes) {
          if (child.nodeType == html_dom.Node.ELEMENT_NODE) {
            final childElement = child as html_dom.Element;
            if (childElement.classes.contains('verse_number')) {
              flushCurrentVerse();
              currentVerseNumber = childElement.text.trim(); // Store as String
            } else {
              currentVerseText.write(childElement.outerHtml);
              // print("childElement.innerHtml: ${childElement.innerHtml}");
            }
          } else if (child.nodeType == html_dom.Node.TEXT_NODE) {
            currentVerseText.write(child.text);
            // print("child.text: ${child.text}");
          }
        }
        flushCurrentVerse();
      }
    }

    // If no verse numbers are found, return the content as a single string
    if (verses.isEmpty) {
      print("extractVerses verses: isEmpty, returning htmlContentOriginal");
      return {"": htmlContentOriginal};
    }

    print("extractVerses verses: $verses");
    return verses;
  } on Exception catch (e) {
    // print("extractVerses error: $e");
    return {"error": e.toString()};
  }
}

void main() {
  String htmlContent =
      '''<p><span class="verse_number">1</span> Venez, crions de j<u>o</u>ie pour le Seigneur,<br />\nacclamons notre
    Roch<u>e</u>r, notre salut !<br /><span class="verse_number">2</span> Allons jusqu'à lu<u>i</u> en rendant
    grâce,<br />\npar nos hymnes de f<u>ê</u>te acclamons-le !<br /><br /><span class="verse_number">3</span> Oui, le
    grand Die<u>u</u>, c'est le Seigneur,<br />\nle grand roi au-dess<u>u</u>s de tous les dieux :<br /><span
        class="verse_number">4</span> il tient en main les profonde<u>u</u>rs de la terre,<br />\net les sommets des
    mont<u>a</u>gnes sont à lui ;<br /><span class="verse_number">5</span> à lui la mer, c'est lu<u>i</u> qui l'a
    faite,<br />\net les terres, car ses m<u>a</u>ins les ont pétries.<br /><br /><span class="verse_number">6</span>
    Entrez, inclinez-vo<u>u</u>s, prosternez-vous,<br />\nadorons le Seigne<u>u</u>r qui nous a faits.<br /><span
        class="verse_number">7</span> Oui, il <u>e</u>st notre Dieu ; +<br />\nnous sommes le pe<u>u</u>ple qu'il
    conduit,<br />\nle troupeau guid<u>é</u> par sa main.<br /><br />\nAujourd'hui écouterez-vo<u>u</u>s sa parole ?
    +<br /><span class="verse_number">8</span> « Ne fermez pas votre cœ<u>u</u>r comme au désert,<br />\ncomme au jour
    de tentati<u>o</u>n et de défi,<br /><span class="verse_number">9</span> où vos pères m'ont tent<u>é</u> et
    provoqué,<br />\net pourtant ils avaient v<u>u</u> mon exploit.<br /><br /><span class="verse_number">10</span> «
    Quarante ans leur générati<u>o</u>n m'a déçu, +<br />\net j'ai dit : Ce peuple a le cœ<u>u</u>r égaré,<br />\nil n'a
    pas conn<u>u</u> mes chemins.<br /><span class="verse_number">11</span> Dans ma colère, j'en ai f<u>a</u>it le
    serment :<br />\nJamais ils n'entrer<u>o</u>nt dans mon repos. »</p>''';
  // final verses = extractVerses(htmlContent);
  // verses.forEach((k, v) => print('Verse $k: $v'));

  String htmlContent2 =
      '''<p>Le premier jour de la semaine,<br />\nMarie Madeleine se rend au tombeau de grand matin ;<br />\nc’était encore les ténèbres.<br />\nElle s’aperçoit que la pierre a été enlevée du tombeau.<br />\nElle court donc trouver Simon-Pierre<br />\net l’autre disciple,<br />\ncelui que Jésus aimait,<br />\net elle leur dit :<br />\n« On a enlevé le Seigneur de son tombeau,<br />\net nous ne savons pas où on l’a déposé. »<br />\nPierre partit donc avec l’autre disciple<br />\npour se rendre au tombeau.<br />\nIls couraient tous les deux ensemble,<br />\nmais l’autre disciple courut plus vite que Pierre<br />\net arriva le premier au tombeau.<br />\nEn se penchant, il s’aperçoit que les linges sont posés à plat ;<br />\ncependant il n’entre pas.<br />\nSimon-Pierre, qui le suivait, arrive à son tour.<br />\nIl entre dans le tombeau ;<br />\nil aperçoit les linges, posés à plat,<br />\nainsi que le suaire qui avait entouré la tête de Jésus,<br />\nnon pas posé avec les linges,<br />\nmais roulé à part à sa place.<br />\nC’est alors qu’entra l’autre disciple,<br />\nlui qui était arrivé le premier au tombeau.<br />\nIl vit, et il crut.<br />\nJusque-là, en effet, les disciples n’avaient pas compris<br />\nque, selon l’Écriture,<br />\nil fallait que Jésus ressuscite d’entre les morts.</p>\n\n<p>– Acclamons la Parole de Dieu.</p>\n\n<p> </p>\n\n<p><em>Au lieu de cet Évangile, on peut lire celui qui a été lu à la Veillée pascale.<br />\nPour la messe du soir de Pâques, on peut aussi lire l’Évangile de Luc 24<strong>,</strong>13-35 ci-dessous.</em></p>''';
  var document = html_parser.parse(htmlContent2);
  print(document.nodes[0]);
}

class LiturgyContent extends StatefulWidget {
  String htmlContent;
  LiturgyContent({Key? key, required this.htmlContent}) : super(key: key);

  @override
  State<LiturgyContent> createState() => _LiturgyContentState();
}

class _LiturgyContentState extends State<LiturgyContent> {
  @override
  Widget build(BuildContext context) {
    Map<String, String> verses = extractVerses(widget.htmlContent);

    return const Placeholder();
  }
}
