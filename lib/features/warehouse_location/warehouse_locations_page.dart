import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/warehouse_locations_mock_data.dart';
import 'widgets/add_location_dialog.dart';
import 'widgets/locations_summary_card.dart';
import 'widgets/warehouse_location_card.dart';
import 'widgets/warehouse_locations_header.dart';

class WarehouseLocationsPage extends StatelessWidget {
  const WarehouseLocationsPage({super.key});

  void _onEditTap(BuildContext context, WarehouseLocation location) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (_) => AddLocationDialog(
        initialName: location.name,
        initialCode: location.code,
        initialCapacity: '${location.capacity}',
        initialDescription: location.area,
        onSave: (name, code, capacity, description) {
          // TODO: Update location (requires backend).
          Navigator.of(context).pop();
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Location update will be available after backend integration.',
                ),
              ),
            );
        },
      ),
    );
  }

  void _onAddLocationTap(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const AddLocationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const WarehouseLocationsHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                96,
              ),
              children: [
                LocationsSummaryCard(summary: warehouseLocationsSummary),
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
                        '${warehouseLocationsMock.length}',
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
                for (final location in warehouseLocationsMock) ...[
                  WarehouseLocationCard(
                    location: location,
                    onEdit: () => _onEditTap(context, location),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddLocationTap(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Location',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}