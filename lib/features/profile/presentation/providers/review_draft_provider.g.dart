// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewDraftNotifierHash() =>
    r'481893ac4e0483ecf0f61b5f57a29253afd8b9ed'; // pragma: allowlist secret

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ReviewDraftNotifier
    extends BuildlessAutoDisposeNotifier<ReviewDraft?> {
  late final String transactionId;

  ReviewDraft? build(String transactionId);
}

/// Provides draft persistence for review screen.
///
/// Reads/writes to SharedPreferences. Garbage-collects expired drafts on build.
///
/// Copied from [ReviewDraftNotifier].
@ProviderFor(ReviewDraftNotifier)
const reviewDraftNotifierProvider = ReviewDraftNotifierFamily();

/// Provides draft persistence for review screen.
///
/// Reads/writes to SharedPreferences. Garbage-collects expired drafts on build.
///
/// Copied from [ReviewDraftNotifier].
class ReviewDraftNotifierFamily extends Family<ReviewDraft?> {
  /// Provides draft persistence for review screen.
  ///
  /// Reads/writes to SharedPreferences. Garbage-collects expired drafts on build.
  ///
  /// Copied from [ReviewDraftNotifier].
  const ReviewDraftNotifierFamily();

  /// Provides draft persistence for review screen.
  ///
  /// Reads/writes to SharedPreferences. Garbage-collects expired drafts on build.
  ///
  /// Copied from [ReviewDraftNotifier].
  ReviewDraftNotifierProvider call(String transactionId) {
    return ReviewDraftNotifierProvider(transactionId);
  }

  @override
  ReviewDraftNotifierProvider getProviderOverride(
    covariant ReviewDraftNotifierProvider provider,
  ) {
    return call(provider.transactionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'reviewDraftNotifierProvider';
}

/// Provides draft persistence for review screen.
///
/// Reads/writes to SharedPreferences. Garbage-collects expired drafts on build.
///
/// Copied from [ReviewDraftNotifier].
class ReviewDraftNotifierProvider
    extends AutoDisposeNotifierProviderImpl<ReviewDraftNotifier, ReviewDraft?> {
  /// Provides draft persistence for review screen.
  ///
  /// Reads/writes to SharedPreferences. Garbage-collects expired drafts on build.
  ///
  /// Copied from [ReviewDraftNotifier].
  ReviewDraftNotifierProvider(String transactionId)
    : this._internal(
        () => ReviewDraftNotifier()..transactionId = transactionId,
        from: reviewDraftNotifierProvider,
        name: r'reviewDraftNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$reviewDraftNotifierHash,
        dependencies: ReviewDraftNotifierFamily._dependencies,
        allTransitiveDependencies:
            ReviewDraftNotifierFamily._allTransitiveDependencies,
        transactionId: transactionId,
      );

  ReviewDraftNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.transactionId,
  }) : super.internal();

  final String transactionId;

  @override
  ReviewDraft? runNotifierBuild(covariant ReviewDraftNotifier notifier) {
    return notifier.build(transactionId);
  }

  @override
  Override overrideWith(ReviewDraftNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ReviewDraftNotifierProvider._internal(
        () => create()..transactionId = transactionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        transactionId: transactionId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ReviewDraftNotifier, ReviewDraft?>
  createElement() {
    return _ReviewDraftNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReviewDraftNotifierProvider &&
        other.transactionId == transactionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, transactionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReviewDraftNotifierRef on AutoDisposeNotifierProviderRef<ReviewDraft?> {
  /// The parameter `transactionId` of this provider.
  String get transactionId;
}

class _ReviewDraftNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<ReviewDraftNotifier, ReviewDraft?>
    with ReviewDraftNotifierRef {
  _ReviewDraftNotifierProviderElement(super.provider);

  @override
  String get transactionId =>
      (origin as ReviewDraftNotifierProvider).transactionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
