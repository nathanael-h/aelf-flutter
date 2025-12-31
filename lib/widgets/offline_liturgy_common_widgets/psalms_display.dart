import 'package:aelf_flutter/widgets/liturgy_part_commentary.dart';
import 'package:aelf_flutter/widgets/liturgy_part_subtitle.dart';
import 'package:aelf_flutter/widgets/liturgy_part_content_title.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/parsers/hebrew_greek_yaml_parser.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/tools/data_loader.dart';

class PsalmDisplayWidget extends StatefulWidget {
  const PsalmDisplayWidget({
    super.key,
    required this.psalmKey,
    required this.psalms,
    required this.dataLoader,
    this.antiphon1,
    this.antiphon2,
    this.antiphon3,
  });

  final String? psalmKey;
  final Map<String, dynamic> psalms;
  final DataLoader dataLoader;
  final String? antiphon1;
  final String? antiphon2;
  final String? antiphon3;

  @override
  State<PsalmDisplayWidget> createState() => _PsalmDisplayWidgetState();
}

class _PsalmDisplayWidgetState extends State<PsalmDisplayWidget> {
  bool useAncientLanguage = false;
  dynamic ancientPsalm;
  bool isLoadingAncient = false;

  bool get _hasAntiphon => widget.antiphon1 != null;

  Future<void> _loadAncientPsalm() async {
    if (widget.psalmKey == null) return;

    setState(() {
      isLoadingAncient = true;
    });

    final loadedPsalm = await PsalmsLibrary.getPsalmAncient(
      widget.psalmKey!,
      widget.dataLoader,
    );

    if (mounted) {
      setState(() {
        ancientPsalm = loadedPsalm;
        isLoadingAncient = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.psalmKey == null || widget.psalms[widget.psalmKey] == null) {
      return const SizedBox.shrink();
    }

    // Choose which psalm to display based on language selection
    final dynamic psalm = useAncientLanguage && ancientPsalm != null
        ? ancientPsalm
        : widget.psalms[widget.psalmKey];

    if (isLoadingAncient) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: _buildPsalmContent(psalm),
    );
  }

  List<Widget> _buildPsalmContent(dynamic psalm) {
    return [
      // Psalm title
      LiturgyPartContentTitle(psalm.getTitle),

      // Psalm subtitle (conditional)
      if (psalm.getSubtitle != null) LiturgyPartSubtitle(psalm.getSubtitle),

      // Psalm commentary (conditional)
      if (psalm.getCommentary != null) ...[
        LiturgyPartCommentary(psalm.getCommentary),
        SizedBox(height: spaceBetweenElements),
      ],

      // Language toggle
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Français'),
          Switch(
            value: useAncientLanguage,
            onChanged: (value) async {
              if (value && ancientPsalm == null) {
                await _loadAncientPsalm();
              }
              setState(() {
                useAncientLanguage = value;
              });
            },
          ),
          const Text('Grec-Hébreu'),
        ],
      ),
      SizedBox(height: spaceBetweenElements),

      // Antiphon before Psalm
      if (_hasAntiphon) ...[
        _buildAntiphon(),
        SizedBox(height: spaceBetweenElements),
      ],

      // Psalm content with verse numbers
      // For Hebrew/Greek text, detect text direction (RTL for Hebrew, LTR for Greek)
      Builder(
        builder: (context) {
          final content = psalm.getContent;

          // For ancient languages, use YAML parser with appropriate text direction
          if (useAncientLanguage) {
            // Detect text direction: if contains Hebrew letters, use RTL
            final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(content);

            return HebrewGreekPsalmFromYaml(
              yamlContent: content,
              textStyle: const TextStyle(
                fontFamily: 'GentiumPlus',
                fontSize: 18,
                height: 1.6,
                color: Colors.black,
              ),
              textDirection: hasHebrew ? TextDirection.rtl : TextDirection.ltr,
            );
          }

          // For French, use the psalm parser with verse numbers
          return PsalmFromHtml(htmlContent: content);
        },
      ),

      // Antiphon after Psalm
      if (_hasAntiphon) ...[
        SizedBox(height: spaceBetweenElements),
        _buildAntiphon(),
      ],
    ];
  }

  Widget _buildAntiphon() {
    return AntiphonWidget(
      antiphon1: widget.antiphon1!,
      antiphon2: widget.antiphon2,
      antiphon3: widget.antiphon3,
    );
  }
}
