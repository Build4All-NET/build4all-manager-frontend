import 'package:flutter_test/flutter_test.dart';

import 'package:build4all_manager/features/owner/social/data/services/instagram_compat.dart';

/// Pure-function tests for [InstagramCompat]. Mirrors the backend
/// `AspectRatioProbeWireMockTest` rules so wire- and client-side
/// verdicts stay aligned.
void main() {
  group('happy paths', () {
    test('square JPEG 1080x1080 accepted', () {
      final v = InstagramCompat.check(
          width: 1080, height: 1080, bytes: 500000, mimeType: 'image/jpeg');
      expect(v.accepted, isTrue);
      expect(v.aspectRatio, closeTo(1.0, 0.001));
    });

    test('portrait 4:5 (1080x1350) accepted', () {
      final v = InstagramCompat.check(
          width: 1080, height: 1350, bytes: 700000, mimeType: 'image/jpeg');
      expect(v.accepted, isTrue);
    });

    test('landscape 1.91:1 (1080x566) accepted', () {
      final v = InstagramCompat.check(
          width: 1080, height: 566, bytes: 400000, mimeType: 'image/jpeg');
      expect(v.accepted, isTrue);
    });

    test('mimeType is case-insensitive and trimmed', () {
      final v = InstagramCompat.check(
          width: 1080, height: 1080, bytes: 1, mimeType: '  IMAGE/JPEG  ');
      expect(v.accepted, isTrue);
    });
  });

  group('rejections', () {
    test('PNG is rejected as unsupported format', () {
      final v = InstagramCompat.check(
          width: 1080, height: 1080, bytes: 1, mimeType: 'image/png');
      expect(v.accepted, isFalse);
      expect(v.rejectedReason, InstagramRejectionReason.unsupportedFormat);
    });

    test('WebP is rejected as unsupported format', () {
      final v = InstagramCompat.check(
          width: 1080, height: 1080, bytes: 1, mimeType: 'image/webp');
      expect(v.rejectedReason, InstagramRejectionReason.unsupportedFormat);
    });

    test('HEIF is rejected as unsupported format', () {
      final v = InstagramCompat.check(
          width: 1080, height: 1080, bytes: 1, mimeType: 'image/heic');
      expect(v.rejectedReason, InstagramRejectionReason.unsupportedFormat);
    });

    test('too tall (ratio < 0.8) is rejected', () {
      // 500x1500 = 0.33 → tooTall
      final v = InstagramCompat.check(
          width: 500, height: 1500, bytes: 1, mimeType: 'image/jpeg');
      expect(v.rejectedReason, InstagramRejectionReason.tooTall);
    });

    test('too wide (ratio > 1.91) is rejected', () {
      // 2400x800 = 3.0 → tooWide
      final v = InstagramCompat.check(
          width: 2400, height: 800, bytes: 1, mimeType: 'image/jpeg');
      expect(v.rejectedReason, InstagramRejectionReason.tooWide);
    });

    test('too narrow (width < 320) is rejected', () {
      final v = InstagramCompat.check(
          width: 200, height: 200, bytes: 1, mimeType: 'image/jpeg');
      expect(v.rejectedReason, InstagramRejectionReason.tooNarrow);
    });

    test('over 8 MB is rejected as fileTooLarge', () {
      final v = InstagramCompat.check(
          width: 1080,
          height: 1080,
          bytes: InstagramImageSpec.maxBytes + 1,
          mimeType: 'image/jpeg');
      expect(v.rejectedReason, InstagramRejectionReason.fileTooLarge);
    });

    test('zero dimensions surface as unreadable', () {
      final v = InstagramCompat.check(
          width: 0, height: 0, bytes: 1, mimeType: 'image/jpeg');
      expect(v.rejectedReason, InstagramRejectionReason.unreadable);
    });
  });

  group('boundary aspect ratios', () {
    test('exactly 4:5 portrait accepted', () {
      final v = InstagramCompat.check(
          width: 1080, height: 1350, bytes: 1, mimeType: 'image/jpeg');
      expect(v.accepted, isTrue);
    });

    test('exactly 1.91:1 landscape accepted', () {
      // 1080 / 566 = 1.908... — within tolerance
      final v = InstagramCompat.check(
          width: 1080, height: 566, bytes: 1, mimeType: 'image/jpeg');
      expect(v.accepted, isTrue);
    });

    test('one pixel taller than 4:5 is rejected', () {
      // 1080 / 1351 ≈ 0.7994 → fails minAspectRatio
      final v = InstagramCompat.check(
          width: 1080, height: 1351, bytes: 1, mimeType: 'image/jpeg');
      expect(v.rejectedReason, InstagramRejectionReason.tooTall);
    });
  });

  group('verdict ergonomics', () {
    test('aspect ratio reported for accepted images', () {
      final v = InstagramCompat.check(
          width: 1200, height: 800, bytes: 1, mimeType: 'image/jpeg');
      expect(v.aspectRatio, closeTo(1.5, 0.01));
    });

    test('every rejection reason has a non-empty label and explanation', () {
      for (final r in InstagramRejectionReason.values) {
        expect(r.label, isNotEmpty, reason: '$r missing label');
        expect(r.explanation, isNotEmpty, reason: '$r missing explanation');
      }
    });
  });
}
