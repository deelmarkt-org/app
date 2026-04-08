import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';

part 'review_draft_provider.g.dart';

/// Persisted draft data for a review in progress.
///
/// Stored in SharedPreferences under key `review_draft_{transactionId}`.
/// Garbage-collects drafts older than 30 days on each build.
class ReviewDraft {
  const ReviewDraft({
    required this.rating,
    required this.body,
    required this.idempotencyKey,
    required this.lastModifiedAt,
  });

  final double rating;
  final String body;
  final String idempotencyKey;
  final DateTime lastModifiedAt;

  static const _maxAgeDays = 30;

  factory ReviewDraft.fromJson(Map<String, dynamic> json) {
    return ReviewDraft(
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      body: json['body'] as String? ?? '',
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      lastModifiedAt:
          DateTime.tryParse(json['lastModifiedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'body': body,
    'idempotencyKey': idempotencyKey,
    'lastModifiedAt': lastModifiedAt.toIso8601String(),
  };

  bool get isExpired =>
      DateTime.now().difference(lastModifiedAt).inDays > _maxAgeDays;

  ReviewDraft copyWith({double? rating, String? body}) {
    return ReviewDraft(
      rating: rating ?? this.rating,
      body: body ?? this.body,
      idempotencyKey: idempotencyKey,
      lastModifiedAt: DateTime.now(),
    );
  }
}

/// Provides draft persistence for review screen.
///
/// Reads/writes to SharedPreferences. Garbage-collects expired drafts on build.
@riverpod
class ReviewDraftNotifier extends _$ReviewDraftNotifier {
  static const _keyPrefix = 'review_draft_';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ReviewDraft? build(String transactionId) {
    _garbageCollectExpiredDrafts();
    return _load(transactionId);
  }

  ReviewDraft? _load(String txnId) {
    final raw = _prefs.getString('$_keyPrefix$txnId');
    if (raw == null) return null;
    try {
      final draft = ReviewDraft.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (draft.isExpired) {
        _prefs.remove('$_keyPrefix$txnId');
        return null;
      }
      return draft;
    } on Object {
      _prefs.remove('$_keyPrefix$txnId');
      return null;
    }
  }

  /// Persist the current draft state.
  void save(ReviewDraft draft) {
    state = draft;
    _prefs.setString('$_keyPrefix$transactionId', jsonEncode(draft.toJson()));
  }

  /// Remove the draft after successful submission.
  void clear() {
    state = null;
    _prefs.remove('$_keyPrefix$transactionId');
  }

  void _garbageCollectExpiredDrafts() {
    final keys =
        _prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
    for (final key in keys) {
      final raw = _prefs.getString(key);
      if (raw == null) continue;
      try {
        final draft = ReviewDraft.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (draft.isExpired) _prefs.remove(key);
      } on Object {
        _prefs.remove(key);
      }
    }
  }
}
