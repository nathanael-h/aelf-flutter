import 'package:flutter/material.dart';
import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/utils/bible_reference_fetcher.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';

class PsalmDisplayWidget extends StatelessWidget {
  const PsalmDisplayWidget({
    super.key,
    required this.psalm,
    this.antiphon1,
    this.antiphon2,
    this.antiphon3,
    this.verseAfter,
    this.imprecatory = true,
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;
  final String? verseAfter;
  final bool imprecatory;

  @override
  Widget build(BuildContext context) {
    // Local copy for null-promotion
    final p = psalm;
    if (p == null) return const SizedBox.shrink();

    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);

    // --- Title Formatting ---
    final shortRef = p.shortReference;
    final bool showShortInTitle = shortRef != null &&
        (shortRef.startsWith('AT') || shortRef.startsWith('NT'));
    final displayTitle =
        showShortInTitle ? '${p.title} ($shortRef)' : (p.title ?? '');

    // --- Biblical Reference Button ---
    Widget Function(double zoom)? biblicalRefTrailing;
    final bibRef = p.biblicalReference;
    if (bibRef != null) {
      biblicalRefTrailing = (zoom) => GestureDetector(
            onTap: () => refButtonPressed(bibRef, context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book,
                    size: 13 * zoom / 100,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  bibRef,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12 * zoom / 100,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          );
    }

    // --- Antiphon Section ---
    Widget? antiphonBlock;
    if (antiphon1 != null && antiphon1!.isNotEmpty) {
      antiphonBlock = Padding(
        padding: kContentPadding,
        child: AntiphonWidget(
          antiphon1: antiphon1!,
          antiphon2: antiphon2,
          antiphon3: antiphon3,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: kContentPadding,
          child: LiturgyPartContentTitle(
            displayTitle,
            trailing: showShortInTitle ? null : biblicalRefTrailing,
          ),
        ),
        if (p.subtitle != null)
          Padding(
            padding: kContentPadding,
            child: LiturgyPartSubtitle(
              p.subtitle!,
              trailing: showShortInTitle ? biblicalRefTrailing : null,
            ),
          ),
        if (p.commentary != null) ...[
          Padding(
            padding: kContentPadding,
            child: LiturgyPartCommentary(p.commentary!),
          ),
          const SizedBox(height: 12.0),
        ],
        const SizedBox(height: 12.0),
        if (antiphonBlock != null) ...[
          antiphonBlock,
          const SizedBox(height: 12.0),
        ],

        // The main body of the Psalm
        PsalmFromMarkdown(content: p.content, imprecatory: imprecatory),

        if (antiphonBlock != null) ...[
          const SizedBox(height: 12.0),
          antiphonBlock,
        ],
        if (verseAfter != null && verseAfter!.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          Padding(
            padding: kContentPadding,
            child: YamlTextFromString(verseAfter!),
          ),
        ],
      ],
    );
  }
}
