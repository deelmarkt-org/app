// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$conversationListNotifierHash() =>
    r'206a983cc3113ef79715580d00db96de4ebdbff6';

/// Async view-model for the conversation list screen (P-35).
///
/// State transitions: `loading` → `data | error`. Pull-to-refresh calls
/// [refresh] which re-runs the use case and re-enters the loading state
/// while the fetch is in flight.
///
/// Copied from [ConversationListNotifier].
@ProviderFor(ConversationListNotifier)
final conversationListNotifierProvider = AutoDisposeAsyncNotifierProvider<
  ConversationListNotifier,
  List<ConversationEntity>
>.internal(
  ConversationListNotifier.new,
  name: r'conversationListNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationListNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConversationListNotifier =
    AutoDisposeAsyncNotifier<List<ConversationEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
