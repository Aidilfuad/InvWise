import 'package:flutter/material.dart';

import '../../../services/profile_service.dart';
import 'personal_details_card.dart';

class WorkInformationCard extends StatelessWidget {
  const WorkInformationCard({super.key, required this.profile});

  final ProfileLookupResult profile;

  @override
  Widget build(BuildContext context) {
    return InformationCardShell(
      icon: Icons.work_outline,
      title: 'Work Information',
      children: [
        InformationRow(
          label: 'Department',
          value: profile.department ?? '—',
          isFirst: true,
        ),
        InformationRow(label: 'Position', value: profile.position ?? '—'),
      ],
    );
  }
}
