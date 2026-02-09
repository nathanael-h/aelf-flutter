import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:offline_liturgy/assets/libraries/psalms_library.dart';
import 'package:offline_liturgy/classes/psalms_class.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/parsers/psalm_parser.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:aelf_flutter/widgets/offline_liturgy_common_widgets/antiphon_display.dart';
import 'package:aelf_flutter/widgets/liturgy_part_title.dart';

class CanticleWidget extends StatefulWidget {
  final String canticleType; // "magnificat", "benedictus", or "nunc_dimittis"
  final String antiphon1;
  final String? antiphon2;
  final DataLoader dataLoader;
  final Psalm? defaultPsalm;

  const CanticleWidget({
    super.key,
    required this.canticleType,
    required this.antiphon1,
    required this.dataLoader,
    this.antiphon2,
    this.defaultPsalm,
  });

  @override
  State<CanticleWidget> createState() => _CanticleWidgetState();
}

class _CanticleWidgetState extends State<CanticleWidget> {
  dynamic psalm;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load initial canticle according to saved preference
    final useAncient = context.read<LiturgyState>().useAncientLanguage;
    _loadPsalm(useAncient);
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

  Future<void> _loadPsalm(bool useAncient) async {
    if (!useAncient && widget.defaultPsalm != null) {
      if (mounted) {
        setState(() {
          psalm = widget.defaultPsalm;
          isLoading = false;
        });
      }
      return;
    }

    final psalmKey = _getPsalmKey();

    final loadedPsalm = useAncient
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
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        LiturgyPartTitle(psalm.title ?? ''),
        SizedBox(height: spaceBetweenElements),
        // Language toggle - use global LiturgyState
        Consumer<LiturgyState>(
          builder: (context, liturgyState, child) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Français'),
              Switch(
                value: liturgyState.useAncientLanguage,
                onChanged: (value) async {
                  // update provider, then reload canticle in requested language
                  context.read<LiturgyState>().updateUseAncientLanguage(value);
                  setState(() {
                    isLoading = true;
                  });
                  await _loadPsalm(value);
                },
              ),
              const Text('Grec-Hébreu'),
            ],
          ),
        ),
        SizedBox(height: spaceBetweenElements),
        AntiphonWidget(
          antiphon1: widget.antiphon1,
          antiphon2: widget.antiphon2,
        ),
        SizedBox(height: spaceBetweenElements),
        Consumer<LiturgyState>(
          builder: (context, liturgyState, child) => PsalmFromHtml(
            htmlContent: psalm.getContent,
            verseStyle: liturgyState.useAncientLanguage
                ? const TextStyle(
                    fontFamily: 'GentiumPlus',
                    fontSize: 18,
                    height: 1.6,
                  )
                : null,
          ),
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
