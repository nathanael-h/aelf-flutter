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
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/hebrew_toggle_button.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';

/// The psalm to actually display: its Hebrew variant when [useHebrew] is on
/// and one exists, otherwise the psalm itself unchanged.
Psalm _displayPsalm(Psalm psalm, bool useHebrew) =>
    useHebrew && psalm.hebrew != null ? psalm.hebrew! : psalm;

/// Hebrew needs its own font and right-to-left layout; French/Latin/Greek
/// psalms use the parser's defaults.
TextStyle? _hebrewVerseStyle(bool useHebrew, double zoom) {
  if (!useHebrew) return null;
  return TextStyle(
    fontFamily: 'EzraSIL',
    fontSize: PsalmConfig.textSize * zoom / 100,
    height: PsalmConfig.lineSpacing,
  );
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
    final useHebrew = context.watch<LiturgyState>().useHebrewPsalm;
    final p = _displayPsalm(original, useHebrew);

    // --- Title Formatting ---
    final shortRef = p.shortReference;
    final bool showShortInTitle = shortRef != null &&
        (shortRef.startsWith('AT') || shortRef.startsWith('NT'));
    final displayTitle =
        showShortInTitle ? '${p.title} ($shortRef)' : (p.title ?? '');

    // --- Biblical Reference / Hebrew Toggle Buttons ---
    Widget Function(double zoom)? refTrailing;
    final bibRef = p.biblicalReference;
    if (bibRef != null || original.hebrew != null) {
      refTrailing = (zoom) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (original.hebrew != null) HebrewToggleButton(zoom: zoom),
              if (bibRef != null)
                BiblicalReferenceButton(reference: bibRef, zoom: zoom),
            ],
          );
    }

    final trailingFn = showShortInTitle ? null : refTrailing;

    // --- Antiphon Section ---
    Widget? antiphonBlock;
    if (antiphon1 != null && antiphon1!.isNotEmpty) {
      antiphonBlock = AntiphonFrame(
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
        isScrollMode
            ? LiturgyContentTitle(displayTitle, trailing: trailingFn)
            : LiturgyPartTitle(displayTitle,
                trailing: trailingFn, left: LiturgyRowLeft.indent),
        if (p.subtitle != null)
          OfflineLiturgyPartSubtitle(
            p.subtitle!,
            trailing: showShortInTitle ? refTrailing : null,
            left: LiturgyRowLeft.indent,
          ),
        if (p.commentary != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LiturgyPartCommentary(p.commentary!),
          ),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (antiphonBlock != null) ...[
          // Extra room between the title (or subtitle) and the separator;
          // the commentary already ends with its own spacing.
          if (p.commentary == null) SizedBox(height: 8.0 * zoom / 100),
          antiphonBlock,
          SizedBox(height: 14.0 * zoom / 100),
        ],
        if (svgData != null && svgData!.isNotEmpty)
          PsalmToneWidget(svgData: svgData!),

        // The main body of the Psalm
        PsalmFromMarkdown(
          content: p.content,
          verseStyle: _hebrewVerseStyle(useHebrew, zoom),
          textDirection: useHebrew ? TextDirection.rtl : null,
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
    final useHebrew = context.watch<LiturgyState>().useHebrewPsalm;
    final p = _displayPsalm(original, useHebrew);

    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);

    final shortRef = p.shortReference;
    final bool showShortInTitle = shortRef != null &&
        (shortRef.startsWith('AT') || shortRef.startsWith('NT'));
    final displayTitle =
        showShortInTitle ? '${p.title} ($shortRef)' : (p.title ?? '');

    Widget Function(double zoom)? refTrailing;
    final bibRef = p.biblicalReference;
    if (bibRef != null || original.hebrew != null) {
      refTrailing = (zoom) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (original.hebrew != null) HebrewToggleButton(zoom: zoom),
              if (bibRef != null)
                BiblicalReferenceButton(reference: bibRef, zoom: zoom),
            ],
          );
    }

    final trailingFn = showShortInTitle ? null : refTrailing;

    Widget? antiphonBlock;
    if (antiphon1 != null && antiphon1!.isNotEmpty) {
      antiphonBlock = AntiphonFrame(
        child: AntiphonWidget(
            antiphon1: antiphon1!, antiphon2: antiphon2, antiphon3: antiphon3),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        isScrollMode
            ? LiturgyContentTitle(displayTitle, trailing: trailingFn)
            : LiturgyPartTitle(displayTitle,
                trailing: trailingFn, left: LiturgyRowLeft.indent),
        if (p.subtitle != null)
          OfflineLiturgyPartSubtitle(
            p.subtitle!,
            trailing: showShortInTitle ? refTrailing : null,
            left: LiturgyRowLeft.indent,
          ),
        if (p.commentary != null) ...[
          Padding(
              padding: kContentPadding,
              child: LiturgyPartCommentary(p.commentary!)),
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (antiphonBlock != null) ...[
          // Extra room between the title (or subtitle) and the separator;
          // the commentary already ends with its own spacing.
          if (p.commentary == null) SizedBox(height: 8.0 * zoom / 100),
          antiphonBlock,
          SizedBox(height: 14.0 * zoom / 100),
        ],
      ],
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
    final useHebrew = context.watch<LiturgyState>().useHebrewPsalm;
    final p = _displayPsalm(original, useHebrew);

    Widget? antiphonBlock;
    if (antiphon1 != null && antiphon1!.isNotEmpty) {
      antiphonBlock = AntiphonFrame(
        child: AntiphonWidget(
            antiphon1: antiphon1!, antiphon2: antiphon2, antiphon3: antiphon3),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PsalmFromMarkdown(
          content: p.content,
          verseStyle: _hebrewVerseStyle(useHebrew, zoom),
          textDirection: useHebrew ? TextDirection.rtl : null,
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
