import 'package:flutter/material.dart';

enum AdjustmentType {
  add('Add Stock', Icons.add_circle_outline_rounded),
  remove('Remove Stock', Icons.remove_circle_outline_rounded);

  const AdjustmentType(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum ReasonCode {
  restock('Restock', Icons.factory_rounded),
  production('Production', Icons.engineering_rounded),
  returned('Return', Icons.assignment_return_rounded),
  damaged('Damaged', Icons.warning_rounded),
  auditFix('Audit Fix', Icons.fact_check_outlined);

  const ReasonCode(this.label, this.icon);

  final String label;
  final IconData icon;
}
