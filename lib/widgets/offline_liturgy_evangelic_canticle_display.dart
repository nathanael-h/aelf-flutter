import 'package:flutter/material.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_antiphon_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';

class CanticleWidget extends StatefulWidget {
  final String canticleType; // "magnificat", "benedictus", or "nunc_dimittis"
  final String antiphon1;
  final String? antiphon2;
  final DataLoader dataLoader;

  const CanticleWidget({
    super.key,
    required this.canticleType,
    required this.antiphon1,
    required this.dataLoader,
    this.antiphon2,
  });

  @override
  State<CanticleWidget> createState() => _CanticleWidgetState();
}

class _CanticleWidgetState extends State<CanticleWidget> {
  dynamic psalm;
  bool isLoading = true;
  bool useAncientLanguage = false;

  @override
  void initState() {
    super.initState();
    _loadPsalm();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getPsalmKey() {
    switch (widget.canticleType.toLowerCase()) {
      case 'magnificat':
        return 'NT_1';
      case 'benedictus':
        return 'NT_2';
      case 'nunc_dimittis':
        return 'NT_3';
      default:
        throw ArgumentError('Invalid canticle type: ${widget.canticleType}');
    }
  }

  Future<void> _loadPsalm() async {
    final psalmKey = _getPsalmKey();

    final loadedPsalm = useAncientLanguage
        ? await PsalmsLibrary.getPsalmAncient(psalmKey, widget.dataLoader)
        : await PsalmsLibrary.getPsalm(psalmKey, widget.dataLoader);

    if (mounted) {
      setState(() {
        psalm = loadedPsalm;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (psalm == null) {
      return const Center(child: Text('Canticle not found'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        LiturgyPartTitle(psalm.title ?? ''),
        SizedBox(height: spaceBetweenElements),
        // Language toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Français'),
            Switch(
              value: useAncientLanguage,
              onChanged: (value) {
                setState(() {
                  useAncientLanguage = value;
                  isLoading = true;
                });
                _loadPsalm();
              },
            ),
            const Text('Grec-Hébreu'),
          ],
        ),
        SizedBox(height: spaceBetweenElements),
        AntiphonWidget(
          antiphon1: widget.antiphon1,
          antiphon2: widget.antiphon2,
        ),
        SizedBox(height: spaceBetweenElements),
        PsalmFromHtml(
          htmlContent: psalm.getContent,
          verseStyle: useAncientLanguage
              ? const TextStyle(
                  fontFamily: 'GentiumPlus',
                  fontSize: 18,
                  height: 1.6,
                )
              : null,
        ),
        SizedBox(height: spaceBetweenElements),
        AntiphonWidget(
          antiphon1: widget.antiphon1,
          antiphon2: widget.antiphon2,
        ),
      ],
    );
  }
}
