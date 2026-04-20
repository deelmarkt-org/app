// Smoke test for the cards barrel — keeps the barrel honest by confirming
// every export is actually a symbol the dependency graph can resolve.
// Individual behaviours are covered by the per-widget test files
// (`deel_card_test.dart`, `stat_card_test.dart`, etc.).
import 'package:deelmarkt/widgets/cards/cards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cards barrel exports every card widget as a Type', () {
    expect(DeelCard, isA<Type>());
    expect(DeelCardImage, isA<Type>());
    expect(DeelCardSkeleton, isA<Type>());
    expect(DeelCardTokens, isA<Type>());
    expect(StatCard, isA<Type>());
  });
}
