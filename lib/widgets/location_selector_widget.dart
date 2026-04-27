import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_liturgy/offline_liturgy.dart';
import 'package:aelf_flutter/states/liturgyState.dart';

class LocationSelectorWidget extends StatefulWidget {
  final Function(String) onLocationSelected;
  final String? currentLocationId;

  const LocationSelectorWidget({
    super.key,
    required this.onLocationSelected,
    this.currentLocationId,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  List<LocationNode>? _tree;
  bool _isLoading = true;
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = widget.currentLocationId;
    _loadTree();
  }

  Future<void> _loadTree() async {
    try {
      final tree = await context.read<LiturgyState>().locationTree;
      if (mounted) {
        setState(() {
          _tree = tree;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  void _selectLocation(String locationId) {
    setState(() {
      _selectedLocationId = locationId;
    });
    widget.onLocationSelected(locationId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tree == null || _tree!.isEmpty) {
      return const Center(
          child: Text('Erreur de chargement des localisations'));
    }

    return ListView(
      children:
          _tree!.map((node) => _buildLocationTile(node, 0)).toList(),
    );
  }

  Widget _buildLocationTile(LocationNode node, int depth) {
    final isSelected = _selectedLocationId == node.location.id;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 32.0),
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -2),
            leading: Icon(
              _iconFor(node.location.geography),
              color: isSelected ? Theme.of(context).colorScheme.secondary : null,
              size: depth > 0 ? 20 : null,
            ),
            title: Text(
              node.location.frenchName,
              style: TextStyle(
                fontWeight: isSelected
                    ? FontWeight.bold
                    : (depth == 0 ? FontWeight.w600 : FontWeight.normal),
                fontSize: depth == 0 ? 16 : null,
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
            ),
            onTap: () => _selectLocation(node.location.id),
          ),
        ),
        ...node.children
            .map((child) => _buildLocationTile(child, depth + 1)),
        if (depth == 0) const Divider(height: 1),
      ],
    );
  }

  IconData _iconFor(LocationGeography geo) {
    return switch (geo) {
      LocationGeography.continent => Icons.public,
      LocationGeography.country => Icons.flag,
      LocationGeography.diocese => Icons.location_city,
      LocationGeography.city => Icons.location_on,
      LocationGeography.church => Icons.church,
      LocationGeography.community => Icons.people,
    };
  }
}

/// Show location selector in a bottom sheet
Future<void> showLocationSelector(
  BuildContext context, {
  required Function(String) onLocationSelected,
  String? currentLocationId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                const Text(
                  'Choisir une localisation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: LocationSelectorWidget(
              onLocationSelected: onLocationSelected,
              currentLocationId: currentLocationId,
            ),
          ),
        ],
      ),
    ),
  );
}
