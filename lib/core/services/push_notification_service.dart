import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/services/app_logger.dart';

part 'push_notification_service.g.dart';

const _logTag = 'Push';
const _tokenColumn = 'token';

/// Handles FCM token registration and push notification setup.
///
/// - Requests notification permission on iOS/Android
/// - Registers the FCM token in `device_tokens` table
/// - Listens for token refreshes and updates the table
/// - Handles foreground message display
///
/// Call [initPushNotifications] after user is authenticated.
/// Reference: docs/epics/E04-messaging.md §Push notifications
@Riverpod(keepAlive: true)
class PushNotificationService extends _$PushNotificationService {
  @override
  Future<void> build() async {
    // No-op on build — call init() after auth.
  }

  /// Initialise push notifications for the authenticated user.
  /// Should be called once after successful login.
  Future<void> init() async {
    if (kIsWeb) return; // FCM push not supported on web MVP

    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS requires explicit prompt; Android auto-grants).
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.info('Push notifications denied by user', tag: _logTag);
      return;
    }

    // Get current token and register it.
    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refreshes (happens when app is reinstalled, etc.).
    messaging.onTokenRefresh.listen(_registerToken);

    // Handle foreground messages (show local notification or update UI).
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Register or update the FCM token in the device_tokens table.
  Future<void> _registerToken(String token) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final nativePlatform = Platform.isIOS ? 'ios' : 'android';
    final platform = kIsWeb ? 'web' : nativePlatform;

    // Upsert — if the token already exists, update the timestamp.
    try {
      await client.from('device_tokens').upsert({
        'user_id': userId,
        _tokenColumn: token,
        'platform': platform,
      }, onConflict: _tokenColumn);
      AppLogger.info('FCM token registered ($platform)', tag: _logTag);
    } on PostgrestException catch (e) {
      AppLogger.warning(
        'Failed to register FCM token: ${e.message}',
        tag: _logTag,
      );
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info(
      'Foreground message: ${message.notification?.title}',
      tag: _logTag,
    );
    // Foreground notification display is handled by the chat Riverpod
    // providers — Supabase Realtime already updates the conversation list
    // and message thread in real-time. The push notification is only
    // needed when the app is in background/terminated.
  }

  /// Remove the current device token on logout.
  Future<void> removeToken() async {
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    if (token == null) return;

    final client = Supabase.instance.client;
    try {
      await client.from('device_tokens').delete().eq(_tokenColumn, token);
    } on PostgrestException catch (e) {
      AppLogger.warning(
        'Failed to remove FCM token: ${e.message}',
        tag: _logTag,
      );
    }
  }
}
