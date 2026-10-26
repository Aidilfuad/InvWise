import 'package:flutter/material.dart';

import '../data/personal_information_mock_data.dart';
import 'personal_details_card.dart';

class AccountInformationCard extends StatelessWidget {
  const AccountInformationCard({super.key, required this.data});

  final PersonalInformationData data;

  @override
  Widget build(BuildContext context) {
    return InformationCardShell(
      icon: Icons.shield_outlined,
      title: 'Account Information',
      children: [
        InformationRow(
          label: 'Username',
          value: data.username,
          isFirst: true,
        ),
        InformationRow(label: 'Last Login', value: data.lastLogin),
        InformationRow(
          label: 'Account Created Date',
          value: data.accountCreated,
        ),
      ],
    );
  }
}