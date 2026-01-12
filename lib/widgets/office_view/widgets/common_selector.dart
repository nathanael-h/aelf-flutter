import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/app_screens/layout_config.dart';
import 'package:yaml/yaml.dart';

/// Widget for selecting a common (with auto-loading titles)
class CommonSelector extends StatefulWidget {
  const CommonSelector({
    super.key,
    required this.resolved,
    required this.dataLoader,
    required this.onCommonChanged,
  });

  final ResolvedOffice resolved;
  final DataLoader dataLoader;
  final ValueChanged<String?> onCommonChanged;

  @override
  State<CommonSelector> createState() => _CommonSelectorState();
}

class _CommonSelectorState extends State<CommonSelector> {
  Map<String, String> commonTitles = {};
  bool isLoadingTitles = true;

  @override
  void initState() {
    super.initState();
    _loadCommonTitles();
  }

  Future<void> _loadCommonTitles() async {
    final commonList = _getCommonList();
    if (commonList == null || commonList.isEmpty) {
      setState(() => isLoadingTitles = false);
      return;
    }

    final titles = <String, String>{};
    for (final commonCode in commonList) {
      try {
        final filePath = 'calendar_data/commons/$commonCode.yaml';
        final fileContent = await widget.dataLoader.loadYaml(filePath);

        if (fileContent.isNotEmpty) {
          final yamlData = loadYaml(fileContent);
          final data = _convertYamlToDart(yamlData);
          final commonTitle = data['commonTitle'] as String?;
          titles[commonCode] = commonTitle ?? commonCode;
        } else {
          titles[commonCode] = commonCode;
        }
      } catch (e) {
        titles[commonCode] = commonCode;
      }
    }

    if (mounted) {
      setState(() {
        commonTitles = titles;
        isLoadingTitles = false;
      });
    }
  }

  dynamic _convertYamlToDart(dynamic value) {
    if (value is YamlMap) {
      return value.map((key, val) =>
          MapEntry(key.toString(), _convertYamlToDart(val)));
    } else if (value is YamlList) {
      return value.map((item) => _convertYamlToDart(item)).toList();
    } else {
      return value;
    }
  }

  List<String>? _getCommonList() {
    try {
      final list = (widget.resolved.definition as dynamic).commonList as List<dynamic>?;
      return list?.map((e) => e.toString()).toList();
    } catch (e) {
      return null;
    }
  }

  int _getPrecedence() {
    try {
      return (widget.resolved.definition as dynamic).precedence as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final commonList = _getCommonList();
    if (commonList == null || commonList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Sélectionner un commun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFEFE3CE),
            ),
            child: DropdownButton<String?>(
              value: widget.resolved.selectedCommon,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              dropdownColor: const Color(0xFFEFE3CE),
              hint: const Text('Choisir un commun',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              items: [
                if (_getPrecedence() > 6)
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Pas de commun',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ...commonList.map(
                  (common) => DropdownMenuItem<String?>(
                    value: common,
                    child: Text(
                      commonTitles[common] ?? common,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ),
              ],
              onChanged: widget.onCommonChanged,
            ),
          ),
        ),
        SizedBox(height: spaceBetweenElements),
      ],
    );
  }
}
