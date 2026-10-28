import '../../../services/activity_log_service.dart';

enum ActivityFilter {
  all,
  inventoryCreated,
  inventoryUpdated,
  inventoryDeleted,
  stockAdjustment,
  receipt,
  issue,
  returnItem,
  transfer,
}

extension ActivityFilterX on ActivityFilter {
  String get label => switch (this) {
    ActivityFilter.all => 'All',
    ActivityFilter.inventoryCreated => 'Create Item',
    ActivityFilter.inventoryUpdated => 'Update Item',
    ActivityFilter.inventoryDeleted => 'Delete Item',
    ActivityFilter.stockAdjustment => 'Adjustment',
    ActivityFilter.receipt => 'Receipt',
    ActivityFilter.issue => 'Issue',
    ActivityFilter.returnItem => 'Return',
    ActivityFilter.transfer => 'Transfer',
  };

  ActivityEventType? get type => switch (this) {
    ActivityFilter.all => null,
    ActivityFilter.inventoryCreated => ActivityEventType.inventoryCreated,
    ActivityFilter.inventoryUpdated => ActivityEventType.inventoryUpdated,
    ActivityFilter.inventoryDeleted => ActivityEventType.inventoryDeleted,
    ActivityFilter.stockAdjustment => ActivityEventType.stockAdjustment,
    ActivityFilter.receipt => ActivityEventType.receipt,
    ActivityFilter.issue => ActivityEventType.issue,
    ActivityFilter.returnItem => ActivityEventType.returnItem,
    ActivityFilter.transfer => ActivityEventType.transfer,
  };
}
