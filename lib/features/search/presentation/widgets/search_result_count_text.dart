import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';

/// Live-region result count line shown above the search result grid.
///
/// Wrapped in `Semantics(liveRegion: true)` so screen readers announce
/// every new total when the user mutates the filter (per #210 a11y
/// review).
class SearchResultCountText extends StatelessWidget {
  const SearchResultCountText({required this.data, super.key});

  final SearchState data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Semantics(
      liveRegion: true,
      child: Text(
        'search.resultsFor'.tr(
          namedArgs: {'query': data.filter.query, 'count': '${data.total}'},
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color:
              isDark
                  ? DeelmarktColors.darkOnSurfaceSecondary
                  : DeelmarktColors.neutral500,
        ),
      ),
    );
  }
}
