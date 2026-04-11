import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

/// Shimmer loading skeleton for the admin dashboard.
///
/// Renders placeholder shapes for the stat card grid, SLA progress bar,
/// and activity feed while real data is being fetched.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminLoadingSkeleton extends StatelessWidget {
  const AdminLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCardRow(),
            const SizedBox(height: Spacing.s6),
            _buildSlaBarSkeleton(),
            const SizedBox(height: Spacing.s6),
            _buildActivityFeedSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardRow() {
    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : Spacing.s2,
              right: index == 3 ? 0 : Spacing.s2,
            ),
            child: const SkeletonBox(borderRadius: DeelmarktRadius.xl),
          ),
        );
      }),
    );
  }

  Widget _buildSlaBarSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLine(width: 180, height: 14),
        SizedBox(height: Spacing.s3),
        SkeletonLine(height: 8, borderRadius: DeelmarktRadius.full),
        SizedBox(height: Spacing.s2),
        SkeletonLine(width: 240, height: 12),
      ],
    );
  }

  Widget _buildActivityFeedSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: 140, height: 14),
        const SizedBox(height: Spacing.s4),
        ...List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.s3),
            child: _buildActivityRowSkeleton(),
          );
        }),
      ],
    );
  }

  Widget _buildActivityRowSkeleton() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonCircle(size: 32),
        SizedBox(width: Spacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: 200, height: 12),
              SizedBox(height: Spacing.s2),
              SkeletonLine(width: 160, height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
