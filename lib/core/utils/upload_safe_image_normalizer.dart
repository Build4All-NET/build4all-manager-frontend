import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UploadSafeImageNormalizer {
  const UploadSafeImageNormalizer._();

  /// iOS photos can arrive as HEIC / HDR / wide-color images.
  /// Re-encoding them to plain JPEG before preview/upload avoids the
  /// occasional green-tint issue seen on some devices.
  static Future<File> normalizeForUpload(
    File input, {
    String prefix = 'upload_image',
    int quality = 88,
    int maxWidth = 2048,
    int maxHeight = 2048,
  }) async {
    if (kIsWeb) return input;
    if (!await input.exists()) return input;

    // Keep Android path untouched unless you want global normalization later.
    if (!Platform.isIOS) return input;

    final tempDir = await getTemporaryDirectory();
    final safePrefix = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final outputPath = p.join(
      tempDir.path,
      '${safePrefix}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      input.absolute.path,
      outputPath,
      format: CompressFormat.jpeg,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
      autoCorrectionAngle: true,
      keepExif: false,
      numberOfRetries: 3,
    );

    if (result == null) return input;
    return File(result.path);
  }

  static Future<List<File>> normalizeMany(
    Iterable<File> files, {
    String prefix = 'upload_image',
    int quality = 88,
    int maxWidth = 2048,
    int maxHeight = 2048,
  }) async {
    final out = <File>[];
    var i = 0;

    for (final file in files) {
      out.add(
        await normalizeForUpload(
          file,
          prefix: '${prefix}_$i',
          quality: quality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
      );
      i++;
    }

    return out;
  }
}
