import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/offline_liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_frame.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_widget.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_language_variant.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';

/// Resolves the display language for [original] from the shared
/// preference, once, so every caller works from the same (language,
/// displayed-variant) pair. Narrows the Provider dependency to just this
/// one field, instead of rebuilding on every unrelated LiturgyState change.
({PsalmLanguage language, Psalm displayPsalm}) _resolveDisplay(
    BuildContext context, Psalm original) {
  final useOriginal =
      context.select<LiturgyState, bool>((s) => s.useOriginalPsalmLanguage);
  final language = resolvePsalmLanguage(original, useOriginal);
  return (
    language: language,
    displayPsalm: displayPsalmFor(original, language),
  );
}

/// The title text and its trailing biblical-reference button, shared by
/// every psalm/canticle display. [p] is the displayed-language variant, so
/// the title and its short reference (`AT N`/`NT N`) follow suit; when the
/// short reference is folded into the title itself, the trailing button
/// moves to the subtitle row instead (both header-builders below do this).
({
  String displayTitle,
  bool showShortInTitle,
  Widget Function(double zoom)? refTrailing
}) _titleInfo(Psalm p) {
  final shortRef = p.shortReference;
  final showShortInTitle = shortRef != null &&
      (shortRef.startsWith('AT') || shortRef.startsWith('NT'));
  final displayTitle =
      showShortInTitle ? '${p.title} ($shortRef)' : (p.title ?? '');
  final bibRef = p.biblicalReference;
  final refTrailing = bibRef != null
      ? (double zoom) => BiblicalReferenceButton(reference: bibRef, zoom: zoom)
      : null;
  return (
    displayTitle: displayTitle,
    showShortInTitle: showShortInTitle,
    refTrailing: refTrailing,
  );
}

/// The opening/closing antiphon block, identical across every psalm and
/// canticle display — `null` when there is no antiphon.
Widget? antiphonBlockFor(
    String? antiphon1, String? antiphon2, String? antiphon3) {
  if (antiphon1 == null || antiphon1.isEmpty) return null;
  return AntiphonFrame(
    child: AntiphonWidget(
      antiphon1: antiphon1,
      antiphon2: antiphon2,
      antiphon3: antiphon3,
    ),
  );
}

/// The header shared by [PsalmDisplayWidget] and [PsalmDisplayHeader]:
/// title, subtitle, commentary and opening antiphon. [original] carries
/// the subtitle/commentary (always French — generated Hebrew/Greek
/// variants never have them); [displayPsalm] carries the title/reference
/// in whichever language is actually shown.
List<Widget> _psalmHeaderChildren({
  required Psalm original,
  required Psalm displayPsalm,
  required bool isScrollMode,
  required double zoom,
  required Widget? antiphonBlock,
}) {
  final title = _titleInfo(displayPsalm);
  final trailingFn = title.showShortInTitle ? null : title.refTrailing;

  return [
    isScrollMode
        ? LiturgyContentTitle(title.displayTitle, trailing: trailingFn)
        : LiturgyPartTitle(title.displayTitle,
            trailing: trailingFn, left: LiturgyRowLeft.indent),
    if (original.subtitle != null)
      OfflineLiturgyPartSubtitle(
        original.subtitle!,
        trailing: title.showShortInTitle ? title.refTrailing : null,
        left: LiturgyRowLeft.indent,
      ),
    if (original.commentary != null) ...[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: LiturgyPartCommentary(original.commentary!),
      ),
      SizedBox(height: 12.0 * zoom / 100),
    ],
    if (antiphonBlock != null) ...[
      // Extra room between the title (or subtitle) and the separator;
      // the commentary already ends with its own spacing.
      if (original.commentary == null) SizedBox(height: 8.0 * zoom / 100),
      antiphonBlock,
      SizedBox(height: 14.0 * zoom / 100),
    ],
  ];
}

class PsalmDisplayWidget extends StatelessWidget {
  const PsalmDisplayWidget({
    super.key,
    required this.psalm,
    this.antiphon1,
    this.antiphon2,
    this.antiphon3,
    this.verseAfter,
    this.svgData,
    this.isScrollMode = false,
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;
  final String? verseAfter;
  final List<String>? svgData;
  final bool isScrollMode;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    // Local copy for null-promotion
    final original = psalm;
    if (original == null) return const SizedBox.shrink();
    final (language: language, displayPsalm: p) =
        _resolveDisplay(context, original);
    final antiphonBlock = antiphonBlockFor(antiphon1, antiphon2, antiphon3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._psalmHeaderChildren(
          original: original,
          displayPsalm: p,
          isScrollMode: isScrollMode,
          zoom: zoom,
          antiphonBlock: antiphonBlock,
        ),
        if (svgData != null && svgData!.isNotEmpty)
          PsalmToneWidget(svgData: svgData!),

        // The main body of the Psalm
        PsalmFromMarkdown(
          content: p.content,
          verseStyle: verseStyleFor(language, zoom),
          textDirection: textDirectionFor(language),
        ),

        if (antiphonBlock != null) ...[
          SizedBox(height: 14.0 * zoom / 100),
          antiphonBlock,
        ],
        if (verseAfter != null && verseAfter!.isNotEmpty) ...[
          SizedBox(height: 12.0 * zoom / 100),
          LiturgyRow(
            left: LiturgyRowLeft.none,
            builder: (context, zoom) => YamlTextFromString(verseAfter!),
          ),
        ],
      ],
    );
  }
}

/// Header portion of a psalm display: title, subtitle, commentary, opening antiphon.
/// Used as a sliver peer with [PsalmDisplayBody] when a sticky SVG tone is present.
class PsalmDisplayHeader extends StatelessWidget {
  const PsalmDisplayHeader({
    super.key,
    required this.psalm,
    this.antiphon1,
    this.antiphon2,
    this.antiphon3,
    this.isScrollMode = false,
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;
  final bool isScrollMode;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final original = psalm;
    if (original == null) return const SizedBox.shrink();
    final (language: _, displayPsalm: p) = _resolveDisplay(context, original);
    final antiphonBlock = antiphonBlockFor(antiphon1, antiphon2, antiphon3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _psalmHeaderChildren(
        original: original,
        displayPsalm: p,
        isScrollMode: isScrollMode,
        zoom: zoom,
        antiphonBlock: antiphonBlock,
      ),
    );
  }
}

/// Body portion of a psalm display: psalm text, closing antiphon, verse after.
/// Used as a sliver peer with [PsalmDisplayHeader] when a sticky SVG tone is present.
class PsalmDisplayBody extends StatelessWidget {
  const PsalmDisplayBody({
    super.key,
    required this.psalm,
    this.antiphon1,
    this.antiphon2,
    this.antiphon3,
    this.verseAfter,
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;
  final String? verseAfter;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final original = psalm;
    if (original == null) return const SizedBox.shrink();
    final (language: language, displayPsalm: p) =
        _resolveDisplay(context, original);
    final antiphonBlock = antiphonBlockFor(antiphon1, antiphon2, antiphon3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PsalmFromMarkdown(
          content: p.content,
          verseStyle: verseStyleFor(language, zoom),
          textDirection: textDirectionFor(language),
        ),
        if (antiphonBlock != null) ...[
          SizedBox(height: 14.0 * zoom / 100),
          antiphonBlock,
        ],
        if (verseAfter != null && verseAfter!.isNotEmpty) ...[
          SizedBox(height: 12.0 * zoom / 100),
          LiturgyRow(
            left: LiturgyRowLeft.none,
            builder: (context, zoom) => YamlTextFromString(verseAfter!),
          ),
        ],
      ],
    );
  }
}
