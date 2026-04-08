// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_profile_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicProfileNotifierHash() =>
    r'd511c62843fe463f70c48e42285b89a0e382a560'; // pragma: allowlist secret

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

abstract class _$PublicProfileNotifier
    extends BuildlessAutoDisposeNotifier<PublicProfileState> {
  late final String userId;

  PublicProfileState build(String userId);
}

/// ViewModel for the public seller profile screen (P-39).
///
/// Per-section independent [AsyncValue] — error in one section
/// does not block others (Tier-1 pattern, ref ProfileNotifier).
///
/// Reference: docs/epics/E06-trust-moderation.md §Public Profile
///
/// Copied from [PublicProfileNotifier].
@ProviderFor(PublicProfileNotifier)
const publicProfileNotifierProvider = PublicProfileNotifierFamily();

/// ViewModel for the public seller profile screen (P-39).
///
/// Per-section independent [AsyncValue] — error in one section
/// does not block others (Tier-1 pattern, ref ProfileNotifier).
///
/// Reference: docs/epics/E06-trust-moderation.md §Public Profile
///
/// Copied from [PublicProfileNotifier].
class PublicProfileNotifierFamily extends Family<PublicProfileState> {
  /// ViewModel for the public seller profile screen (P-39).
  ///
  /// Per-section independent [AsyncValue] — error in one section
  /// does not block others (Tier-1 pattern, ref ProfileNotifier).
  ///
  /// Reference: docs/epics/E06-trust-moderation.md §Public Profile
  ///
  /// Copied from [PublicProfileNotifier].
  const PublicProfileNotifierFamily();

  /// ViewModel for the public seller profile screen (P-39).
  ///
  /// Per-section independent [AsyncValue] — error in one section
  /// does not block others (Tier-1 pattern, ref ProfileNotifier).
  ///
  /// Reference: docs/epics/E06-trust-moderation.md §Public Profile
  ///
  /// Copied from [PublicProfileNotifier].
  PublicProfileNotifierProvider call(String userId) {
    return PublicProfileNotifierProvider(userId);
  }

  @override
  PublicProfileNotifierProvider getProviderOverride(
    covariant PublicProfileNotifierProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publicProfileNotifierProvider';
}

/// ViewModel for the public seller profile screen (P-39).
///
/// Per-section independent [AsyncValue] — error in one section
/// does not block others (Tier-1 pattern, ref ProfileNotifier).
///
/// Reference: docs/epics/E06-trust-moderation.md §Public Profile
///
/// Copied from [PublicProfileNotifier].
class PublicProfileNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<
          PublicProfileNotifier,
          PublicProfileState
        > {
  /// ViewModel for the public seller profile screen (P-39).
  ///
  /// Per-section independent [AsyncValue] — error in one section
  /// does not block others (Tier-1 pattern, ref ProfileNotifier).
  ///
  /// Reference: docs/epics/E06-trust-moderation.md §Public Profile
  ///
  /// Copied from [PublicProfileNotifier].
  PublicProfileNotifierProvider(String userId)
    : this._internal(
        () => PublicProfileNotifier()..userId = userId,
        from: publicProfileNotifierProvider,
        name: r'publicProfileNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$publicProfileNotifierHash,
        dependencies: PublicProfileNotifierFamily._dependencies,
        allTransitiveDependencies:
            PublicProfileNotifierFamily._allTransitiveDependencies,
        userId: userId,
      );

  PublicProfileNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  PublicProfileState runNotifierBuild(
    covariant PublicProfileNotifier notifier,
  ) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(PublicProfileNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PublicProfileNotifierProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<PublicProfileNotifier, PublicProfileState>
  createElement() {
    return _PublicProfileNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicProfileNotifierProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicProfileNotifierRef
    on AutoDisposeNotifierProviderRef<PublicProfileState> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _PublicProfileNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          PublicProfileNotifier,
          PublicProfileState
        >
    with PublicProfileNotifierRef {
  _PublicProfileNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as PublicProfileNotifierProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
