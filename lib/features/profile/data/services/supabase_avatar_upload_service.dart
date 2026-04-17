import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/domain/services/avatar_upload_service.dart';

/// Uploads avatar images to the `avatars` Supabase Storage bucket.
///
/// Path pattern: `avatars/<userId>/<timestamp>.<ext>`
/// RLS enforces folder-level isolation per user.
///
/// Bucket is public — [getPublicUrl] resolves without a signed-URL TTL so
/// avatars render on profile cards and listings. See migration
/// `supabase/migrations/20260415150000_r05_avatars_bucket.sql` for the
/// bucket + RLS definition.
///
/// Reference: docs/screens/07-profile/01-own-profile.md
class SupabaseAvatarUploadService implements AvatarUploadService {
  SupabaseAvatarUploadService(this._client);

  final SupabaseClient _client;

  static const _bucket = 'avatars';

  /// Maximum file size: 15 MiB (matches Storage bucket limit).
  static const maxFileSizeBytes = 15 * 1024 * 1024;

  /// Allowed image file extensions.
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};

  @override
  Future<String> upload({
    required String userId,
    required String filePath,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SupabaseAvatarUploadService does not support web. '
        'Use a web-specific implementation with Uint8List.',
      );
    }

    final file = File(filePath);

    await _validateFile(file);

    final extension = p.extension(filePath).replaceFirst('.', '').toLowerCase();
    final storagePath =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage
        .from(_bucket)
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from(_bucket).getPublicUrl(storagePath);
  }

  Future<void> _validateFile(File file) async {
    final extension =
        p.extension(file.path).replaceFirst('.', '').toLowerCase();

    if (!_allowedExtensions.contains(extension)) {
      throw FormatException(
        'Unsupported image format: $extension. '
        'Allowed: ${_allowedExtensions.join(', ')}',
      );
    }

    final size = await file.length();
    if (size > maxFileSizeBytes) {
      throw FormatException(
        'Image too large: ${(size / 1024 / 1024).toStringAsFixed(1)} MB. '
        'Maximum: ${maxFileSizeBytes ~/ 1024 ~/ 1024} MB',
      );
    }
  }
}
