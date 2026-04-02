import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/search/data/shared_prefs_recent_searches_repo.dart';
import 'package:deelmarkt/features/search/domain/recent_searches_repository.dart';
import 'package:deelmarkt/features/search/domain/search_listings_usecase.dart';

/// Recent searches repository — SharedPreferences backed.
final recentSearchesRepositoryProvider = Provider<RecentSearchesRepository>(
  (ref) => SharedPrefsRecentSearchesRepo(ref.watch(sharedPreferencesProvider)),
);

/// Search use case provider.
final searchListingsUseCaseProvider = Provider<SearchListingsUseCase>(
  (ref) => SearchListingsUseCase(ref.watch(listingRepositoryProvider)),
);
