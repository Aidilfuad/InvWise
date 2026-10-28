import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/warehouse_location_service.dart';
import 'widgets/add_location_dialog.dart';
import 'widgets/locations_summary_card.dart';
import 'widgets/warehouse_location_card.dart';
import 'widgets/warehouse_locations_header.dart';

class WarehouseLocationsPage extends StatefulWidget {
  const WarehouseLocationsPage({super.key});

  @override
  State<WarehouseLocationsPage> createState() => _WarehouseLocationsPageState();
}

class _WarehouseLocationsPageState extends State<WarehouseLocationsPage> {
  final WarehouseLocationService _service = WarehouseLocationService();

  List<WarehouseLocation> _locations = const [];
  WarehouseLocationsSummary _summary = const WarehouseLocationsSummary(
    activeLocations: 0,
    totalCapacity: 0,
    utilizationPercent: 0,
  );
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final locations = await _service.getLocations(includeInactive: true);
      if (!mounted) return;
      final activeLocations = locations
          .where((location) => location.isActive)
          .toList();
      final capacity = activeLocations.fold<double>(
        0,
        (total, location) => total + location.capacity,
      );
      final usage = activeLocations.fold<double>(
        0,
        (total, location) => total + location.usage,
      );
      setState(() {
        _locations = locations;
        _summary = WarehouseLocationsSummary(
          activeLocations: activeLocations.length,
          totalCapacity: capacity,
          utilizationPercent: capacity <= 0
              ? 0
              : ((usage / capacity) * 100).round().clamp(0, 100).toInt(),
        );
        _isLoading = false;
      });
    } on WarehouseLocationServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load warehouse locations: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _showLocationDialog({WarehouseLocation? location}) async {
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AddLocationDialog(
        initialName: location?.name,
        initialCode: location?.code,
        initialCapacity: location == null ? null : '${location.capacity}',
        initialDescription: location?.description,
        initialAddress: location?.address,
        onSave: (name, code, capacityText, description, address) async {
          final capacity = double.tryParse(capacityText.trim());
          if (capacity == null) {
            throw const WarehouseLocationServiceException(
              'Enter a valid non-negative capacity.',
            );
          }
          if (location == null) {
            await _service.createLocation(
              name: name,
              code: code,
              capacity: capacity,
              description: description,
              address: address,
            );
          } else {
            await _service.updateLocation(
              id: location.id,
              name: name,
              code: code,
              capacity: capacity,
              description: description,
              address: address,
            );
          }
          if (!context.mounted) return;
          Navigator.of(context).pop();
          await _loadLocations();
          if (!mounted) return;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  location == null
                      ? 'Warehouse location created.'
                      : 'Warehouse location updated.',
                ),
              ),
            );
        },
      ),
    );
  }

  Future<void> _deleteLocation(WarehouseLocation location) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete location?'),
        content: Text(
          'Delete "${location.name}"? Locations referenced by stock records '
          'cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    try {
      await _service.deleteLocation(location.id);
      await _loadLocations();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Location deleted.')));
    } on WarehouseLocationServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const WarehouseLocationsHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadLocations,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        96,
                      ),
                      children: [
                        LocationsSummaryCard(summary: _summary),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              'All locations',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_locations.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_locations.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Text(
                                'No warehouse locations yet.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        for (final location in _locations) ...[
                          WarehouseLocationCard(
                            location: location,
                            onEdit: () =>
                                _showLocationDialog(location: location),
                            onDelete: () => _deleteLocation(location),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Location',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadLocations, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
