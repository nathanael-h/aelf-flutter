import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/utils/bible_language.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/language_toggle_pill.dart';

/// A language-toggle button shown next to a Bible reference, cycling
/// [LiturgyState.bibleTextLanguage] through French/Greek/Hebrew for [book] —
/// a single shared, persisted preference for the Bible reader, the Office
/// of Readings' biblical reading and the Mass readings alike, independent
/// of the evangelic canticles' and psalms' own language toggles (different
/// texts, resolved differently — see [LiturgyState.cycleBibleTextLanguage]).
class BibleLanguageButton extends StatelessWidget {
  final String book;
  final double zoom;

  const BibleLanguageButton({super.key, required this.book, this.zoom = 100});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LiturgyState>().bibleTextLanguage;

    return LanguageTogglePill(
      active: language != BibleLanguage.french,
      onTap: () => context.read<LiturgyState>().cycleBibleTextLanguage(book),
      zoom: zoom,
      showHebrew: true,
    );
  }
}
