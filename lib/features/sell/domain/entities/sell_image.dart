import 'package:equatable/equatable.dart';

/// Upload lifecycle for a picked image.
///
/// * [pending]   — queued, not yet started
/// * [uploading] — actively uploading (Storage PUT or Edge Function invoke)
/// * [uploaded]  — delivery URL available, safe to publish
/// * [failed]    — terminal or retryable failure; see [SellImage.isRetryable]
enum ImageUploadStatus { pending, uploading, uploaded, failed }

/// A single picked image tracked by the listing creation wizard.
///
/// Each image carries its own upload state so the UI can render spinners,
/// progress overlays, and retry affordances independently per tile.
///
/// Pure domain entity — no Flutter/Supabase imports.
class SellImage extends Equatable {
  const SellImage({
    required this.id,
    required this.localPath,
    this.status = ImageUploadStatus.pending,
    this.storagePath,
    this.deliveryUrl,
    this.publicId,
    this.errorKey,
    this.userRetryCount = 0,
    this.isRetryable = true,
  });

  /// Stable id generated when the image is picked. Used for id-based
  /// state patching so out-of-order uploads cannot overwrite each other.
  final String id;

  /// Absolute path to the picked file on device.
  final String localPath;

  final ImageUploadStatus status;

  /// `<user_id>/<uuid>.<ext>` within the `listings-images` bucket.
  /// Set once the Storage upload succeeds.
  final String? storagePath;

  /// Final Cloudinary delivery URL. Set on successful Edge Function response.
  final String? deliveryUrl;

  /// Cloudinary public_id. Used for targeted deletes/transforms.
  /// Set on successful Edge Function response. Null until uploaded.
  final String? publicId;

  /// l10n key for the current error, null when no error.
  final String? errorKey;

  /// Number of times the user has manually retried this image.
  /// Internal queue retries are not counted here.
  final int userRetryCount;

  /// False for terminal failures (virus blocked, file too large, auth).
  /// True for transient failures (network, 5xx, rate limit).
  final bool isRetryable;

  bool get isUploaded => status == ImageUploadStatus.uploaded;
  bool get isFailed => status == ImageUploadStatus.failed;
  bool get isPending => !isUploaded && !isFailed;
  bool get canRetry => isFailed && isRetryable;

  /// Immutable update. Nullable fields use `T? Function()?` to distinguish
  /// "keep current value" (null sentinel) from "clear to null".
  SellImage copyWith({
    ImageUploadStatus? status,
    String? Function()? storagePath,
    String? Function()? deliveryUrl,
    String? Function()? publicId,
    String? Function()? errorKey,
    int? userRetryCount,
    bool? isRetryable,
  }) {
    return SellImage(
      id: id,
      localPath: localPath,
      status: status ?? this.status,
      storagePath: storagePath != null ? storagePath() : this.storagePath,
      deliveryUrl: deliveryUrl != null ? deliveryUrl() : this.deliveryUrl,
      publicId: publicId != null ? publicId() : this.publicId,
      errorKey: errorKey != null ? errorKey() : this.errorKey,
      userRetryCount: userRetryCount ?? this.userRetryCount,
      isRetryable: isRetryable ?? this.isRetryable,
    );
  }

  /// Serialise to JSON for draft persistence.
  Map<String, Object?> toJson() => {
    'id': id,
    'localPath': localPath,
    'storagePath': storagePath,
    'deliveryUrl': deliveryUrl,
    'publicId': publicId,
  };

  /// Deserialise from persisted draft JSON.
  ///
  /// Always restores to [ImageUploadStatus.uploaded] — drafts only persist
  /// images that have already been uploaded (see [DraftPersistenceService]).
  factory SellImage.fromJson(Map<String, dynamic> json) {
    return SellImage(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      status: ImageUploadStatus.uploaded,
      storagePath: json['storagePath'] as String?,
      deliveryUrl: json['deliveryUrl'] as String?,
      publicId: json['publicId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    localPath,
    status,
    storagePath,
    deliveryUrl,
    publicId,
    errorKey,
    userRetryCount,
    isRetryable,
  ];
}
