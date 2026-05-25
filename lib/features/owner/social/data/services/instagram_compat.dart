/// Local mirror of the backend's `InstagramImageSpec`. Lets the product
/// editor warn the user as soon as they pick an image, before any
/// network round-trip to the backend.
///
/// Keep these constants in sync with
/// `com.build4all.socialMedia.publisher.meta.InstagramImageSpec`.
class InstagramImageSpec {
  /// Widest aspect ratio Meta accepts (landscape). 1.91 : 1.
  static const double maxAspectRatio = 1.91;

  /// Tallest aspect ratio Meta accepts (portrait). 4 : 5 = 0.8.
  static const double minAspectRatio = 0.8;

  /// Meta's documented minimum width.
  static const int minWidthPx = 320;

  /// Hard maximum file size.
  static const int maxBytes = 8 * 1024 * 1024;

  /// MIME types Meta accepts for IG feed photos.
  static const List<String> allowedMimeTypes = ['image/jpeg', 'image/jpg'];
}

enum InstagramRejectionReason {
  tooWide,
  tooTall,
  tooNarrow,
  fileTooLarge,
  unsupportedFormat,
  unreadable;

  /// Short label suitable for a chip / inline warning.
  String get label {
    switch (this) {
      case InstagramRejectionReason.tooWide:           return 'Too wide for IG';
      case InstagramRejectionReason.tooTall:           return 'Too tall for IG';
      case InstagramRejectionReason.tooNarrow:         return 'Too narrow for IG';
      case InstagramRejectionReason.fileTooLarge:      return 'Image too large';
      case InstagramRejectionReason.unsupportedFormat: return 'JPEG required';
      case InstagramRejectionReason.unreadable:        return 'Image unreadable';
    }
  }

  /// Longer one-liner the UI tooltip / sheet can show.
  String get explanation {
    switch (this) {
      case InstagramRejectionReason.tooWide:
        return 'Instagram only accepts photos with aspect ratio up to 1.91:1 (landscape). Crop closer to square.';
      case InstagramRejectionReason.tooTall:
        return 'Instagram only accepts photos with aspect ratio down to 4:5 (portrait). Crop closer to square.';
      case InstagramRejectionReason.tooNarrow:
        return 'Instagram requires photos at least ${InstagramImageSpec.minWidthPx}px wide.';
      case InstagramRejectionReason.fileTooLarge:
        return 'Instagram\'s 8 MB per-image cap is exceeded. Re-export at lower quality.';
      case InstagramRejectionReason.unsupportedFormat:
        return 'Instagram only accepts JPEG photos for feed posts. PNG / WebP / HEIF won\'t upload.';
      case InstagramRejectionReason.unreadable:
        return 'Could not read this image\'s dimensions. The file may be corrupted.';
    }
  }
}

/// Result of [InstagramCompat.check].
class InstagramCompatVerdict {
  /// True when the image satisfies every IG constraint.
  final bool accepted;
  final int width;
  final int height;
  final InstagramRejectionReason? rejectedReason;
  final String? detail;

  const InstagramCompatVerdict._({
    required this.accepted,
    required this.width,
    required this.height,
    this.rejectedReason,
    this.detail,
  });

  factory InstagramCompatVerdict.accept(int width, int height) =>
      InstagramCompatVerdict._(accepted: true, width: width, height: height);

  factory InstagramCompatVerdict.reject(
    InstagramRejectionReason reason, {
    int width = 0,
    int height = 0,
    String? detail,
  }) =>
      InstagramCompatVerdict._(
        accepted: false,
        width: width,
        height: height,
        rejectedReason: reason,
        detail: detail,
      );

  /// Aspect ratio width / height. Zero when one of the dimensions is unknown.
  double get aspectRatio => (width <= 0 || height <= 0) ? 0 : width / height;
}

/// Pure-function image compatibility check. Lives outside any widget so it
/// can be unit-tested without flutter_test pumping a frame.
class InstagramCompat {
  /// Check an image's dimensions / size / mime against IG's spec.
  ///
  /// Pass [width] and [height] in pixels, [bytes] (>0) for the file size,
  /// and [mimeType] lowercased ("image/jpeg" / "image/png" / "image/webp").
  static InstagramCompatVerdict check({
    required int width,
    required int height,
    required int bytes,
    required String mimeType,
  }) {
    final mime = mimeType.trim().toLowerCase();

    if (!InstagramImageSpec.allowedMimeTypes.contains(mime)) {
      return InstagramCompatVerdict.reject(
        InstagramRejectionReason.unsupportedFormat,
        width: width,
        height: height,
        detail: 'mimeType=$mime',
      );
    }
    if (width <= 0 || height <= 0) {
      return InstagramCompatVerdict.reject(InstagramRejectionReason.unreadable);
    }
    if (bytes > InstagramImageSpec.maxBytes) {
      return InstagramCompatVerdict.reject(
        InstagramRejectionReason.fileTooLarge,
        width: width,
        height: height,
        detail: '$bytes bytes',
      );
    }
    if (width < InstagramImageSpec.minWidthPx) {
      return InstagramCompatVerdict.reject(
        InstagramRejectionReason.tooNarrow,
        width: width,
        height: height,
      );
    }
    final ratio = width / height;
    if (ratio > InstagramImageSpec.maxAspectRatio) {
      return InstagramCompatVerdict.reject(
        InstagramRejectionReason.tooWide,
        width: width,
        height: height,
      );
    }
    if (ratio < InstagramImageSpec.minAspectRatio) {
      return InstagramCompatVerdict.reject(
        InstagramRejectionReason.tooTall,
        width: width,
        height: height,
      );
    }
    return InstagramCompatVerdict.accept(width, height);
  }
}
