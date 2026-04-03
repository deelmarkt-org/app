import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/domain/entities/category_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/search/data/shared_prefs_recent_searches_repo.dart';
import 'package:deelmarkt/features/search/domain/recent_searches_repository.dart';
import 'package:deelmarkt/features/search/domain/search_listings_usecase.dart';

part 'search_providers.g.dart';

/// Recent searches repository — SharedPreferences backed.
final recentSearchesRepositoryProvider = Provider<RecentSearchesRepository>(
  (ref) => SharedPrefsRecentSearchesRepo(ref.watch(sharedPreferencesProvider)),
);

/// Search use case provider.
final searchListingsUseCaseProvider = Provider<SearchListingsUseCase>(
  (ref) => SearchListingsUseCase(ref.watch(listingRepositoryProvider)),
);

/// Top-level categories for search initial view and filter sheet.
@riverpod
Future<List<CategoryEntity>> topLevelCategories(Ref ref) {
  return ref.watch(categoryRepositoryProvider).getTopLevel();
}
