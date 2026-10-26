import 'package:flutter/material.dart';

import '../data/personal_information_mock_data.dart';
import 'personal_details_card.dart';

class WorkInformationCard extends StatelessWidget {
  const WorkInformationCard({super.key, required this.data});

  final PersonalInformationData data;

  static const Color _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return InformationCardShell(
      icon: Icons.work_outline,
      title: 'Work Information',
      children: [
        InformationRow(
          label: 'Warehouse Assignment',
          value: data.warehouseAssignment,
          isFirst: true,
        ),
        InformationRow(
          label: 'Employment Status',
          value: data.employmentStatus,
          valueColor: _green,
          showDot: true,
        ),
        InformationRow(
          label: 'System Access Level',
          value: data.accessLevel,
        ),
      ],
    );
  }
}