// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewNotifierHash() => r'a1d88c3e67a58e0bf5ac79ba030abce426f97c61';

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

abstract class _$ReviewNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ReviewScreenState> {
  late final String transactionId;

  FutureOr<ReviewScreenState> build(String transactionId);
}

/// Review screen state machine. Reference: E06 §Ratings & Reviews
///
/// Copied from [ReviewNotifier].
@ProviderFor(ReviewNotifier)
const reviewNotifierProvider = ReviewNotifierFamily();

/// Review screen state machine. Reference: E06 §Ratings & Reviews
///
/// Copied from [ReviewNotifier].
class ReviewNotifierFamily extends Family<AsyncValue<ReviewScreenState>> {
  /// Review screen state machine. Reference: E06 §Ratings & Reviews
  ///
  /// Copied from [ReviewNotifier].
  const ReviewNotifierFamily();

  /// Review screen state machine. Reference: E06 §Ratings & Reviews
  ///
  /// Copied from [ReviewNotifier].
  ReviewNotifierProvider call(String transactionId) {
    return ReviewNotifierProvider(transactionId);
  }

  @override
  ReviewNotifierProvider getProviderOverride(
    covariant ReviewNotifierProvider provider,
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
  String? get name => r'reviewNotifierProvider';
}

/// Review screen state machine. Reference: E06 §Ratings & Reviews
///
/// Copied from [ReviewNotifier].
class ReviewNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ReviewNotifier,
          ReviewScreenState
        > {
  /// Review screen state machine. Reference: E06 §Ratings & Reviews
  ///
  /// Copied from [ReviewNotifier].
  ReviewNotifierProvider(String transactionId)
    : this._internal(
        () => ReviewNotifier()..transactionId = transactionId,
        from: reviewNotifierProvider,
        name: r'reviewNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$reviewNotifierHash,
        dependencies: ReviewNotifierFamily._dependencies,
        allTransitiveDependencies:
            ReviewNotifierFamily._allTransitiveDependencies,
        transactionId: transactionId,
      );

  ReviewNotifierProvider._internal(
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
  FutureOr<ReviewScreenState> runNotifierBuild(
    covariant ReviewNotifier notifier,
  ) {
    return notifier.build(transactionId);
  }

  @override
  Override overrideWith(ReviewNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ReviewNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ReviewNotifier, ReviewScreenState>
  createElement() {
    return _ReviewNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReviewNotifierProvider &&
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
mixin ReviewNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<ReviewScreenState> {
  /// The parameter `transactionId` of this provider.
  String get transactionId;
}

class _ReviewNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ReviewNotifier,
          ReviewScreenState
        >
    with ReviewNotifierRef {
  _ReviewNotifierProviderElement(super.provider);

  @override
  String get transactionId => (origin as ReviewNotifierProvider).transactionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
