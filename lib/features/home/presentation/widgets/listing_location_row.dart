import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';

/// Location row showing pin icon + city name + optional distance.
class ListingLocationRow extends StatelessWidget {
  const ListingLocationRow({
    required this.location,
    this.distanceKm,
    super.key,
  });

  final String location;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final text =
        distanceKm != null
            ? '$location · ${Formatters.distanceKm(distanceKm!)}'
            : location;

    return Row(
      children: [
        Icon(
          PhosphorIcons.mapPin(),
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Spacing.s1),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
