enum ActivityType { addItem, editItem, stockIn, stockOut, audit }

enum ActivityFilter { all, addItem, editItem, stockIn, stockOut, audit }

extension ActivityFilterX on ActivityFilter {
  String get label {
    switch (this) {
      case ActivityFilter.all:
        return 'All';
      case ActivityFilter.addItem:
        return 'Add Item';
      case ActivityFilter.editItem:
        return 'Edit Item';
      case ActivityFilter.stockIn:
        return 'Stock In';
      case ActivityFilter.stockOut:
        return 'Stock Out';
      case ActivityFilter.audit:
        return 'Audit';
    }
  }

  ActivityType? get type {
    switch (this) {
      case ActivityFilter.all:
        return null;
      case ActivityFilter.addItem:
        return ActivityType.addItem;
      case ActivityFilter.editItem:
        return ActivityType.editItem;
      case ActivityFilter.stockIn:
        return ActivityType.stockIn;
      case ActivityFilter.stockOut:
        return ActivityType.stockOut;
      case ActivityFilter.audit:
        return ActivityType.audit;
    }
  }
}

class ActivityLogEntry {
  const ActivityLogEntry({
    required this.itemName,
    required this.sku,
    required this.type,
    required this.quantityChange,
    required this.description,
    required this.date,
    required this.time,
    required this.user,
  });

  final String itemName;
  final String sku;
  final ActivityType type;
  final int quantityChange;
  final String description;
  final String date;
  final String time;
  final String user;
}

class ActivityLogMockData {
  const ActivityLogMockData._();

  static const List<ActivityLogEntry> entries = [
    ActivityLogEntry(
      itemName: 'Steel Bearing 40mm',
      sku: 'STB-001',
      type: ActivityType.stockIn,
      quantityChange: 50,
      description: 'Purchase receipt · PO-2026-184',
      date: '06 Oct 2026',
      time: '09:32 AM',
      user: 'Admin',
    ),
    ActivityLogEntry(
      itemName: 'M12 Hex Bolt',
      sku: 'FST-0842',
      type: ActivityType.stockOut,
      quantityChange: -24,
      description: 'Issued to maintenance · WO-0264',
      date: '06 Oct 2026',
      time: '09:18 AM',
      user: 'Alex Morgan',
    ),
    ActivityLogEntry(
      itemName: 'V-Belt A42',
      sku: 'VBT-024',
      type: ActivityType.editItem,
      quantityChange: 0,
      description: 'Rack location updated · B-04 → B-06',
      date: '06 Oct 2026',
      time: '08:45 AM',
      user: 'Priya Shah',
    ),
    ActivityLogEntry(
      itemName: 'Rubber Gasket 16mm',
      sku: 'GSK-016',
      type: ActivityType.addItem,
      quantityChange: 0,
      description: 'Item created · No opening stock',
      date: '05 Oct 2026',
      time: '04:52 PM',
      user: 'Admin',
    ),
    ActivityLogEntry(
      itemName: 'Steel Bearing 40mm',
      sku: 'STB-001',
      type: ActivityType.audit,
      quantityChange: 0,
      description: '120 units verified · No variance',
      date: '05 Oct 2026',
      time: '03:10 PM',
      user: 'Alex Morgan',
    ),
  ];
}