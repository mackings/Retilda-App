import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class _CompressionStep {
  const _CompressionStep(this.quality, this.minDimension);

  final int quality;
  final int minDimension;
}

/// Keeps multi-image uploads under Vercel's serverless function payload
/// limit (~4.5MB per request), which rejects the whole request with a
/// 413 FUNCTION_PAYLOAD_TOO_LARGE before our API code ever runs.
class ImageCompression {
  ImageCompression._();

  static const int maxCombinedBytes = 4 * 1024 * 1024;

  static const List<_CompressionStep> _steps = [
    _CompressionStep(85, 1920),
    _CompressionStep(70, 1600),
    _CompressionStep(55, 1280),
    _CompressionStep(40, 1024),
    _CompressionStep(25, 800),
  ];

  /// Compresses [images] (nulls are kept as-is) only if their combined
  /// size exceeds [maxCombinedBytes], splitting that budget evenly
  /// across the files that are present. Returns a list in the same
  /// order/positions as the input.
  static Future<List<File?>> fitToLimit(List<File?> images) async {
    final present = images.whereType<File>().toList();
    if (present.isEmpty) return images;

    final totalSize = present.fold<int>(0, (sum, f) => sum + f.lengthSync());
    if (totalSize <= maxCombinedBytes) return images;

    final perFileBudget = maxCombinedBytes ~/ present.length;

    final result = <File?>[];
    for (final image in images) {
      if (image == null) {
        result.add(null);
        continue;
      }
      result.add(await _compressToBudget(image, perFileBudget));
    }
    return result;
  }

  static Future<File> _compressToBudget(File file, int budgetBytes) async {
    if (file.lengthSync() <= budgetBytes) return file;

    Uint8List? best;

    for (final step in _steps) {
      final bytes = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: step.quality,
        minWidth: step.minDimension,
        minHeight: step.minDimension,
        format: CompressFormat.jpeg,
      );
      if (bytes == null) continue;

      if (best == null || bytes.length < best.length) {
        best = bytes;
      }
      if (bytes.length <= budgetBytes) break;
    }

    if (best == null) return file;

    final tempDir = await Directory.systemTemp.createTemp('retilda_upload_');
    final compressedFile = File('${tempDir.path}/compressed.jpg');
    await compressedFile.writeAsBytes(best);
    return compressedFile;
  }
}
