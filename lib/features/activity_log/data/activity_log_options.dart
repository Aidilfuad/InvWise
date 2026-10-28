import '../../../services/stock_movement_service.dart';

enum ActivityFilter { all, receipt, issue, transfer, returnItem }

extension ActivityFilterX on ActivityFilter {
  String get label => switch (this) {
    ActivityFilter.all => 'All',
    ActivityFilter.receipt => 'Receipt',
    ActivityFilter.issue => 'Issue',
    ActivityFilter.transfer => 'Transfer',
    ActivityFilter.returnItem => 'Return',
  };

  StockMovementType? get type => switch (this) {
    ActivityFilter.all => null,
    ActivityFilter.receipt => StockMovementType.receipt,
    ActivityFilter.issue => StockMovementType.issue,
    ActivityFilter.transfer => StockMovementType.transfer,
    ActivityFilter.returnItem => StockMovementType.returnItem,
  };
}
