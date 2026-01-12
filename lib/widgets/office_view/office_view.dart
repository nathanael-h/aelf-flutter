import 'package:flutter/material.dart';
import 'package:offline_liturgy/tools/data_loader.dart';
import 'package:aelf_flutter/widgets/office_view/office_config.dart';
import 'package:aelf_flutter/widgets/office_view/office_service.dart';
import 'package:aelf_flutter/widgets/office_view/resolved_office.dart';
import 'package:aelf_flutter/widgets/office_view/office_tab_builder.dart';

/// Generic office view widget that works for all office types
/// (Readings, Morning, Compline, Vespers, etc.)
class OfficeView extends StatefulWidget {
  const OfficeView({
    super.key,
    required this.config,
    required this.definitions,
    required this.date,
    required this.dataLoader,
    this.additionalData,
  });

  final OfficeConfig config;
  final Map<String, dynamic> definitions;
  final DateTime date;
  final DataLoader dataLoader;
  final dynamic additionalData; // For calendar, etc.

  @override
  State<OfficeView> createState() => _OfficeViewState();
}

class _OfficeViewState extends State<OfficeView> {
  late final OfficeService _service;

  bool _isLoading = true;
  ResolvedOffice? _resolved;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = OfficeService(
      config: widget.config,
      dataLoader: widget.dataLoader,
    );
    _loadOffice();
  }

  @override
  void didUpdateWidget(OfficeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.definitions != widget.definitions) {
      _loadOffice();
    }
  }

  Future<void> _loadOffice({
    String? celebrationKey,
    String? common,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resolved = await _service.resolve(
        definitions: widget.definitions,
        date: widget.date,
        preselectedKey: celebrationKey,
        preselectedCommon: common,
      );

      if (mounted) {
        setState(() {
          _resolved = resolved;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading office: $e';
        });
      }
    }
  }

  Future<void> _onCelebrationChanged(String key) async {
    await _loadOffice(celebrationKey: key, common: _resolved?.selectedCommon);
  }

  Future<void> _onCommonChanged(String? common) async {
    await _loadOffice(celebrationKey: _resolved?.celebrationKey, common: common);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadOffice(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_resolved != null) {
      return OfficeDisplay(
        config: widget.config,
        resolved: _resolved!,
        definitions: widget.definitions,
        dataLoader: widget.dataLoader,
        onCelebrationChanged: _onCelebrationChanged,
        onCommonChanged: _onCommonChanged,
        additionalData: widget.additionalData,
      );
    }

    return const Center(child: Text('No data available'));
  }
}

/// Pure display widget for office
class OfficeDisplay extends StatelessWidget {
  const OfficeDisplay({
    super.key,
    required this.config,
    required this.resolved,
    required this.definitions,
    required this.dataLoader,
    required this.onCelebrationChanged,
    required this.onCommonChanged,
    this.additionalData,
  });

  final OfficeConfig config;
  final ResolvedOffice resolved;
  final Map<String, dynamic> definitions;
  final DataLoader dataLoader;
  final ValueChanged<String> onCelebrationChanged;
  final ValueChanged<String?> onCommonChanged;
  final dynamic additionalData;

  @override
  Widget build(BuildContext context) {
    final tabCount = config.calculateTabCount(
      resolved.psalmodyCount,
      hasTeDeum: resolved.showTeDeum,
    );

    return DefaultTabController(
      length: tabCount,
      child: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              children: _buildTabViews(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = <Tab>[];

    for (int i = 0; i < config.calculateTabCount(
      resolved.psalmodyCount,
      hasTeDeum: resolved.showTeDeum,
    ); i++) {
      final label = config.getTabLabel(
        i,
        resolved.psalmodyCount,
        psalmTitles: resolved.psalmTitles,
        hasTeDeum: resolved.showTeDeum,
      );
      tabs.add(Tab(text: label));
    }

    return Container(
      color: Theme.of(context).primaryColor,
      child: TabBar(
        isScrollable: true,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: tabs,
      ),
    );
  }

  List<Widget> _buildTabViews(BuildContext context) {
    return OfficeTabBuilder.buildTabViews(
      config: config,
      resolved: resolved,
      definitions: definitions,
      dataLoader: dataLoader,
      onCelebrationChanged: onCelebrationChanged,
      onCommonChanged: onCommonChanged,
      additionalData: additionalData,
    );
  }
}
