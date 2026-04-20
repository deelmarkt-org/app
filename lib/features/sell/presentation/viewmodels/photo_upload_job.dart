import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';

/// Mutable job descriptor for [PhotoUploadQueue]; tracks the upload
/// state machine (`pending → uploaded → processed`) so the queue can
/// emit the correct [CancellationToken] cleanup action.
class PhotoUploadJob {
  PhotoUploadJob({
    required this.id,
    required this.localPath,
    required this.token,
  });

  final String id;
  final String localPath;
  final CancellationToken token;

  String? storagePath;
  bool uploadCompleted = false;
  bool processingCompleted = false;
}
