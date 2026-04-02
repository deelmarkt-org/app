/// Local storage interface for recent search queries.
abstract class RecentSearchesRepository {
  /// Get all recent searches, most recent first.
  Future<List<String>> getAll();

  /// Add a query to the front of the list. Deduplicates and caps at 10.
  Future<void> add(String query);

  /// Remove a single query from the list.
  Future<void> remove(String query);

  /// Clear all recent searches.
  Future<void> clear();
}
