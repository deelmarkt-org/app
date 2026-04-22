import 'package:flutter_test/flutter_test.dart';

import 'device_frames.dart';

void main() {
  group('kScreenshotDevices', () {
    test('every frame has finite logical size and positive DPR', () {
      for (final frame in kScreenshotDevices) {
        expect(frame.logicalSize.isFinite, isTrue, reason: frame.toString());
        expect(
          frame.devicePixelRatio,
          greaterThan(0),
          reason: frame.toString(),
        );
      }
    });
  });

  group('kScreenshotDesktopDevices', () {
    test('contains at least one desktop frame', () {
      expect(kScreenshotDesktopDevices, isNotEmpty);
    });

    test('every desktop frame is web platform, finite size, positive DPR', () {
      for (final frame in kScreenshotDesktopDevices) {
        expect(
          frame.platform,
          ScreenshotPlatform.web,
          reason: frame.toString(),
        );
        expect(frame.logicalSize.isFinite, isTrue, reason: frame.toString());
        expect(
          frame.devicePixelRatio,
          greaterThan(0),
          reason: frame.toString(),
        );
      }
    });

    test('desktop_1400 frame matches tokens.md large breakpoint (≥1200px)', () {
      final desktop1400 = kScreenshotDesktopDevices.firstWhere(
        (f) => f.id == 'desktop_1400',
      );
      expect(desktop1400.logicalSize.width, greaterThanOrEqualTo(1200));
    });
  });
}
