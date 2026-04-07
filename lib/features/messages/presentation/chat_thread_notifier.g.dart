// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_thread_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatThreadNotifierHash() =>
    r'af03970c27a1a58a17fdc91a2278e466766fe526';

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

abstract class _$ChatThreadNotifier
    extends BuildlessAutoDisposeAsyncNotifier<ChatThreadState> {
  late final String conversationId;

  FutureOr<ChatThreadState> build(String conversationId);
}

/// Async view-model for P-36. Loads conversation + messages in parallel;
/// supports optimistic send with rollback on failure.
///
/// Copied from [ChatThreadNotifier].
@ProviderFor(ChatThreadNotifier)
const chatThreadNotifierProvider = ChatThreadNotifierFamily();

/// Async view-model for P-36. Loads conversation + messages in parallel;
/// supports optimistic send with rollback on failure.
///
/// Copied from [ChatThreadNotifier].
class ChatThreadNotifierFamily extends Family<AsyncValue<ChatThreadState>> {
  /// Async view-model for P-36. Loads conversation + messages in parallel;
  /// supports optimistic send with rollback on failure.
  ///
  /// Copied from [ChatThreadNotifier].
  const ChatThreadNotifierFamily();

  /// Async view-model for P-36. Loads conversation + messages in parallel;
  /// supports optimistic send with rollback on failure.
  ///
  /// Copied from [ChatThreadNotifier].
  ChatThreadNotifierProvider call(String conversationId) {
    return ChatThreadNotifierProvider(conversationId);
  }

  @override
  ChatThreadNotifierProvider getProviderOverride(
    covariant ChatThreadNotifierProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatThreadNotifierProvider';
}

/// Async view-model for P-36. Loads conversation + messages in parallel;
/// supports optimistic send with rollback on failure.
///
/// Copied from [ChatThreadNotifier].
class ChatThreadNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          ChatThreadNotifier,
          ChatThreadState
        > {
  /// Async view-model for P-36. Loads conversation + messages in parallel;
  /// supports optimistic send with rollback on failure.
  ///
  /// Copied from [ChatThreadNotifier].
  ChatThreadNotifierProvider(String conversationId)
    : this._internal(
        () => ChatThreadNotifier()..conversationId = conversationId,
        from: chatThreadNotifierProvider,
        name: r'chatThreadNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$chatThreadNotifierHash,
        dependencies: ChatThreadNotifierFamily._dependencies,
        allTransitiveDependencies:
            ChatThreadNotifierFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ChatThreadNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  FutureOr<ChatThreadState> runNotifierBuild(
    covariant ChatThreadNotifier notifier,
  ) {
    return notifier.build(conversationId);
  }

  @override
  Override overrideWith(ChatThreadNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatThreadNotifierProvider._internal(
        () => create()..conversationId = conversationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ChatThreadNotifier, ChatThreadState>
  createElement() {
    return _ChatThreadNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatThreadNotifierProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatThreadNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<ChatThreadState> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ChatThreadNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          ChatThreadNotifier,
          ChatThreadState
        >
    with ChatThreadNotifierRef {
  _ChatThreadNotifierProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ChatThreadNotifierProvider).conversationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
