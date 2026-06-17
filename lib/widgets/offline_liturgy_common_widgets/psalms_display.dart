import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:aelf_flutter/widgets/liturgy_row.dart';
import 'package:aelf_flutter/parsers/yaml_text_parser.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/biblical_reference_button.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/psalm_tone_widget.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';

class PsalmDisplayWidget extends StatelessWidget {
  const PsalmDisplayWidget({
    super.key,
    required this.psalm,
    this.antiphon1,
    this.antiphon2,
    this.antiphon3,
    this.verseAfter,
    this.svgData,
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;
  final String? verseAfter;
  final List<String>? svgData;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    // Local copy for null-promotion
    final p = psalm;
    if (p == null) return const SizedBox.shrink();

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
      biblicalRefTrailing =
          (zoom) => BiblicalReferenceButton(reference: bibRef, zoom: zoom);
    }

    // --- Antiphon Section ---
    Widget? antiphonBlock;
    if (antiphon1 != null && antiphon1!.isNotEmpty) {
      antiphonBlock = LiturgyRow(
        builder: (context, zoom) => AntiphonWidget(
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
        LiturgyPartContentTitle(
          displayTitle,
          trailing: showShortInTitle ? null : biblicalRefTrailing,
          hideVerseIdPlaceholder: false,
        ),
        if (p.subtitle != null)
          LiturgyPartSubtitle(
            p.subtitle!,
            trailing: showShortInTitle ? biblicalRefTrailing : null,
            hideVerseIdPlaceholder: false,
          ),
        if (p.commentary != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LiturgyPartCommentary(p.commentary!),
          ),
          const SizedBox(height: 12.0),
        ],
        const SizedBox(height: 12.0),
        if (antiphonBlock != null) ...[
          antiphonBlock,
          SizedBox(height: 12.0 * zoom / 100),
        ],
        if (svgData != null && svgData!.isNotEmpty)
          PsalmToneWidget(svgData: svgData!),

        // The main body of the Psalm
        PsalmFromMarkdown(content: p.content),

        if (antiphonBlock != null) ...[
          SizedBox(height: 20.0 * zoom / 100),
          antiphonBlock,
        ],
        if (verseAfter != null && verseAfter!.isNotEmpty) ...[
          const SizedBox(height: 12.0),
          LiturgyRow(
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
  });

  final Psalm? psalm;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<CurrentZoom>().value;
    final p = psalm;
    if (p == null) return const SizedBox.shrink();

    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);

    final shortRef = p.shortReference;
    final bool showShortInTitle =
        shortRef != null && (shortRef.startsWith('AT') || shortRef.startsWith('NT'));
    final displayTitle = showShortInTitle ? '${p.title} ($shortRef)' : (p.title ?? '');

    Widget Function(double zoom)? biblicalRefTrailing;
    final bibRef = p.biblicalReference;
    if (bibRef != null) {
      biblicalRefTrailing = (zoom) => BiblicalReferenceButton(reference: bibRef, zoom: zoom);
    }

    Widget? antiphonBlock;
    if (antiphon1 != null && antiphon1!.isNotEmpty) {
      antiphonBlock = Padding(
        padding: kContentPadding,
        child: AntiphonWidget(antiphon1: antiphon1!, antiphon2: antiphon2, antiphon3: antiphon3),
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
          Padding(padding: kContentPadding, child: LiturgyPartCommentary(p.commentary!)),
          const SizedBox(height: 12.0),
        ],
        const SizedBox(height: 12.0),
        if (antiphonBlock != null) ...[
          antiphonBlock,
          SizedBox(height: 12.0 * zoom / 100),
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
    final p = psalm;
    if (p == null) return const SizedBox.shrink();

    const kContentPadding = EdgeInsets.symmetric(horizontal: 16.0);

    Widget? antiphonBlock;
    if (antiphon1 != null && antiphon1!.isNotEmpty) {
      antiphonBlock = Padding(
        padding: kContentPadding,
        child: AntiphonWidget(antiphon1: antiphon1!, antiphon2: antiphon2, antiphon3: antiphon3),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PsalmFromMarkdown(content: p.content),
        if (antiphonBlock != null) ...[
          SizedBox(height: 20.0 * zoom / 100),
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
