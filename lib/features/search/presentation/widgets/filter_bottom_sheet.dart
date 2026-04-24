import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_panel.dart';

/// Viewport-height fractions for the filter [DraggableScrollableSheet].
///
/// The ratios are design-driven (search spec `docs/screens/02-home/03-search.md`):
/// the sheet must cover enough of the viewport to show the three primary
/// filters without scrolling, collapse to half height for peek-and-dismiss,
/// and extend near full-screen for long category lists.
const double _filterSheetMinFraction = 0.5;
const double _filterSheetInitialFraction = 0.7;
const double _filterSheetMaxFraction = 0.9;

/// Shows the search filter bottom sheet.
///
/// Delegates the filter UI to the shared [FilterPanel] widget
/// (`variant: FilterPanelVariant.sheet`). The desktop sidebar on
/// `SearchResultsView` renders the same widget with the `sidebar` variant
/// so bottom-sheet and sidebar cannot drift.
void showFilterBottomSheet({
  required BuildContext context,
  required SearchFilter currentFilter,
  required ValueChanged<SearchFilter> onApply,
  bool reduceMotion = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DeelmarktRadius.xl),
      ),
    ),
    transitionAnimationController:
        reduceMotion
            ? AnimationController(
              vsync: Navigator.of(context),
              duration: Duration.zero,
            )
            : null,
    builder:
        (_) => _FilterSheet(currentFilter: currentFilter, onApply: onApply),
  );
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.currentFilter, required this.onApply});

  final SearchFilter currentFilter;
  final ValueChanged<SearchFilter> onApply;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _filterSheetInitialFraction,
      minChildSize: _filterSheetMinFraction,
      maxChildSize: _filterSheetMaxFraction,
      expand: false,
      builder: (context, scrollController) {
        return FilterPanel(
          filter: currentFilter,
          onApply: onApply,
          scrollController: scrollController,
        );
      },
    );
  }
}
