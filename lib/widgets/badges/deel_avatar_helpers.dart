import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Utility helpers for [DeelAvatar] — initials extraction and color hashing.
class DeelAvatarHelpers {
  const DeelAvatarHelpers._();

  /// Extract up to two initials from a display name.
  static String extractInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Deterministic background colour based on name hash.
  static Color backgroundFromName(String name) {
    const colors = [
      DeelmarktColors.secondary,
      DeelmarktColors.primary,
      DeelmarktColors.trustVerified,
      DeelmarktColors.trustEscrow,
      DeelmarktColors.badgeGold,
      DeelmarktColors.accentPurple,
      DeelmarktColors.accentPink,
      DeelmarktColors.accentEmerald,
    ];
    final hash = name.codeUnits.fold<int>(0, (h, c) => h + c);
    return colors[hash % colors.length];
  }
}
