import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';

/// Stub [ImageUploadService] for development and widget tests.
///
/// Simulates a ~100 ms upload and returns predictable [ImageUploadResponse]
/// values so the sell wizard works without a live Supabase project.
///
/// Injected via [imageUploadServiceProvider] when [useMockDataProvider] is
/// true (see `sell_services_providers.dart`).
class MockImageUploadService extends ImageUploadService {
  /// Creates a mock upload service. A placeholder [SupabaseClient] is passed
  /// to the base class but is never used — all methods are overridden.
  MockImageUploadService()
    : super(
        SupabaseClient(
          'https://placeholder.supabase.co',
          'placeholder',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  @override
  Future<ImageUploadResponse> uploadAndProcess(File localFile) async {
    // Simulate a brief network round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final filename = localFile.path.split(RegExp(r'[/\\]')).last;
    return ImageUploadResponse(
      storagePath: 'mock-user/$filename',
      deliveryUrl:
          'https://res.cloudinary.com/demo/image/upload/mock/$filename',
      publicId: 'mock/$filename',
      width: 800,
      height: 600,
      bytes: 102400,
      format: 'jpg',
    );
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {
    // No-op in mock mode — nothing to clean up.
  }
}
