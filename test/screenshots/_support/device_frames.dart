/// Device frame configurations for App Store / Play Console screenshot matrix.
///
/// Resolution reference:
///  iOS 6.7"  — iPhone 15 Pro Max / 16 series  (1290×2796 @3× → logical 430×932)
///  iOS 6.5"  — iPhone 11 Pro Max / XS Max     (1242×2688 @3× → logical 414×896)
///  iOS 5.5"  — iPhone 8 Plus                  (1242×2208 @3× → logical 414×736)
///  iPad 12.9"— iPad Pro 12.9" 6th gen         (2048×2732 @2× → logical 1024×1366)
///  Android phone — Pixel 7 equivalent         (1080×2400 @2.625× → logical ~412×915)
///  Android tablet— Pixel Tablet equivalent    (1600×2560 @2× → logical 800×1280)
///
/// These are the logical (dp) sizes Flutter uses; the physical pixel output is
/// controlled by the devicePixelRatio in [DeviceFrame.toSizeAndDpr].
library;

import 'package:flutter/rendering.dart';

/// One device class for which we generate a screenshot set.
final class DeviceFrame {
  const DeviceFrame({
    required this.id,
    required this.label,
    required this.logicalSize,
    required this.devicePixelRatio,
    required this.platform,
  });

  final String id;
  final String label;
  final Size logicalSize;
  final double devicePixelRatio;
  final ScreenshotPlatform platform;

  Size get physicalSize => Size(
    logicalSize.width * devicePixelRatio,
    logicalSize.height * devicePixelRatio,
  );

  @override
  String toString() =>
      'DeviceFrame($id, ${logicalSize.width}×${logicalSize.height} @${devicePixelRatio}x)';
}

enum ScreenshotPlatform { ios, android, web }

/// The canonical 6-device screenshot matrix defined in PLAN-p43-aso.md §WS-B.
const List<DeviceFrame> kScreenshotDevices = [
  // ── iOS ─────────────────────────────────────────────────────────────────
  DeviceFrame(
    id: 'ios_67',
    label: 'iPhone 6.7"',
    logicalSize: Size(430, 932),
    devicePixelRatio: 3.0,
    platform: ScreenshotPlatform.ios,
  ),
  DeviceFrame(
    id: 'ios_65',
    label: 'iPhone 6.5"',
    logicalSize: Size(414, 896),
    devicePixelRatio: 3.0,
    platform: ScreenshotPlatform.ios,
  ),
  DeviceFrame(
    id: 'ios_55',
    label: 'iPhone 5.5"',
    logicalSize: Size(414, 736),
    devicePixelRatio: 3.0,
    platform: ScreenshotPlatform.ios,
  ),
  DeviceFrame(
    id: 'ios_ipad_129',
    label: 'iPad 12.9"',
    logicalSize: Size(1024, 1366),
    devicePixelRatio: 2.0,
    platform: ScreenshotPlatform.ios,
  ),
  // ── Android ─────────────────────────────────────────────────────────────
  DeviceFrame(
    id: 'android_phone',
    label: 'Android Phone',
    logicalSize: Size(412, 915),
    devicePixelRatio: 2.625,
    platform: ScreenshotPlatform.android,
  ),
  DeviceFrame(
    id: 'android_tablet',
    label: 'Android Tablet',
    logicalSize: Size(800, 1280),
    devicePixelRatio: 2.0,
    platform: ScreenshotPlatform.android,
  ),
];

/// Desktop/web frames introduced for the responsive rollout (#192 → #193/#194/#196).
///
/// NOT consumed by existing screenshot drivers yet — each screen-fix PR opts
/// in by iterating `[...kScreenshotDevices, ...kScreenshotDesktopDevices]` (or
/// the desktop list alone) when it regenerates goldens, so PNGs always reflect
/// the intended fixed state rather than the current broken baseline.
const List<DeviceFrame> kScreenshotDesktopDevices = [
  DeviceFrame(
    id: 'desktop_1400',
    label: 'Desktop 1400',
    logicalSize: Size(1400, 900),
    devicePixelRatio: 1.0,
    platform: ScreenshotPlatform.web,
  ),
];
