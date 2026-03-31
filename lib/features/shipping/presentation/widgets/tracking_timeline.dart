import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';

import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';

/// Vertical tracking timeline showing carrier events for a shipment.
///
/// Displays events chronologically (newest at top) with status indicators.
/// Each event shows: status icon, description, location, timestamp.
///
/// Reference: docs/design-system/patterns.md §Tracking Timeline
class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({required this.events, super.key});

  /// Tracking events in reverse chronological order (newest first).
  final List<TrackingEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (int i = 0; i < events.length; i++)
          _TrackingEventTile(
            event: events[i],
            isFirst: i == 0,
            isLast: i == events.length - 1,
          ),
      ],
    );
  }
}

class _TrackingEventTile extends StatelessWidget {
  const _TrackingEventTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final TrackingEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isActive = isFirst;
    final color =
        isActive ? _statusColor(event.status) : DeelmarktColors.neutral300;

    return Semantics(
      label:
          '${event.description}${event.location != null ? ', ${event.location}' : ''}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _indicator(color),
            const SizedBox(width: Spacing.s3),
            Expanded(child: _content(context, isActive)),
          ],
        ),
      ),
    );
  }

  Widget _indicator(Color color) {
    return SizedBox(
      width: 32,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFirst ? color : DeelmarktColors.neutral100,
              border:
                  isFirst
                      ? null
                      : Border.all(
                        color: DeelmarktColors.neutral300,
                        width: 1.5,
                      ),
            ),
            child: Icon(
              _statusIcon(event.status),
              size: 16,
              color:
                  isFirst ? DeelmarktColors.white : DeelmarktColors.neutral500,
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(width: 2, color: DeelmarktColors.neutral200),
            ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, bool isActive) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : Spacing.s4,
        top: Spacing.s1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color:
                  isActive
                      ? DeelmarktColors.neutral900
                      : DeelmarktColors.neutral500,
            ),
          ),
          if (event.location != null) ...[
            const SizedBox(height: Spacing.s1),
            Row(
              children: [
                Icon(
                  PhosphorIcons.mapPin(),
                  size: 12,
                  color: DeelmarktColors.neutral500,
                ),
                const SizedBox(width: Spacing.s1),
                Flexible(
                  child: Text(
                    event.location!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DeelmarktColors.neutral500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Spacing.s1),
          Text(
            Formatters.shortDateTime(
              event.timestamp,
              locale: Localizations.localeOf(context).languageCode,
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: DeelmarktColors.neutral500),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(TrackingStatus status) => switch (status) {
    TrackingStatus.delivered => DeelmarktColors.success,
    TrackingStatus.outForDelivery => DeelmarktColors.trustEscrow,
    TrackingStatus.deliveryFailed ||
    TrackingStatus.returned => DeelmarktColors.error,
    _ => DeelmarktColors.secondary,
  };

  static IconData _statusIcon(TrackingStatus status) => switch (status) {
    TrackingStatus.labelCreated => PhosphorIcons.tag(),
    TrackingStatus.droppedOff => PhosphorIcons.storefront(),
    TrackingStatus.pickedUp => PhosphorIcons.truckTrailer(),
    TrackingStatus.inTransit => PhosphorIcons.path(),
    TrackingStatus.outForDelivery => PhosphorIcons.bicycle(),
    TrackingStatus.delivered => PhosphorIcons.checkCircle(
      PhosphorIconsStyle.fill,
    ),
    TrackingStatus.deliveryFailed => PhosphorIcons.warningCircle(),
    TrackingStatus.returned => PhosphorIcons.arrowUUpLeft(),
  };
}
