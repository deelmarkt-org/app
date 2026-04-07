import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_top_categories_usecase.dart';

part 'category_browse_notifier.g.dart';

/// Riverpod provider for [GetTopCategoriesUseCase] (category browse screen).
///
/// Separate from [getTopCategoriesUseCaseProvider] in home_notifier to avoid
/// coupling the browse screen lifecycle to the home screen.
final _getTopCategoriesUseCaseProvider = Provider<GetTopCategoriesUseCase>(
  (ref) => GetTopCategoriesUseCase(ref.watch(categoryRepositoryProvider)),
);

@riverpod
class CategoryBrowseNotifier extends _$CategoryBrowseNotifier {
  @override
  Future<List<CategoryEntity>> build() => _fetchCategories();

  Future<List<CategoryEntity>> _fetchCategories() async {
    final getTopCategories = ref.watch(_getTopCategoriesUseCaseProvider);
    return getTopCategories();
  }

  /// Pull-to-refresh with previous state preservation on error.
  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchCategories);

    if (state.hasError && previous != null) {
      AppLogger.error(
        'Failed to refresh categories',
        error: state.error,
        tag: 'category-browse',
      );
      state = AsyncValue.data(previous);
    }
  }
}
