import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Tab bar for profile: Listings and Reviews.
class ProfileTabs extends StatelessWidget {
  const ProfileTabs({required this.controller, super.key});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: [
        Tab(text: 'profile.listings'.tr()),
        Tab(text: 'profile.reviewsTab'.tr()),
      ],
    );
  }
}
