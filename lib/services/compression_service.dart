import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:video_compress/video_compress.dart';

// ---------------------------------------------------------------------------
// Inline models
// ---------------------------------------------------------------------------

class CompressResult {
  final int originalSize;
  final int compressedSize;
  final int savedBytes;
  final String? outputPath;

  const CompressResult({
    required this.originalSize,
    required this.compressedSize,
    required this.savedBytes,
    this.outputPath,
  });

  double get savingsPercent =>
      originalSize > 0 ? (savedBytes / originalSize) * 100.0 : 0.0;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class CompressionService extends ChangeNotifier {
  bool _isCompressing = false;
  double _progress = 0.0;

  bool get isCompressing => _isCompressing;
  double get progress => _progress;

  // -----------------------------------------------------------------------
  // Photo compression
  // -----------------------------------------------------------------------

  /// Compress a photo asset by re-encoding it as JPEG at the given [quality].
  ///
  /// [quality] should be between 0.0 (lowest) and 1.0 (highest).
  /// Returns a [CompressResult] describing the savings achieved.
  Future<CompressResult> compressPhoto(
    String assetId, {
    double quality = 0.6,
  }) async {
    _isCompressing = true;
    _progress = 0.0;
    notifyListeners();

    try {
      final entity = await AssetEntity.fromId(assetId);
      if (entity == null) {
        throw Exception('Asset not found: $assetId');
      }

      final file = await entity.file;
      if (file == null) {
        throw Exception('Could not load file for asset: $assetId');
      }

      final originalBytes = await file.readAsBytes();
      final originalSize = originalBytes.length;

      _progress = 0.3;
      notifyListeners();

      // Decode the image.
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        throw Exception('Could not decode image for asset: $assetId');
      }

      _progress = 0.6;
      notifyListeners();

      // Re-encode as JPEG with the requested quality (0-100 int scale).
      final jpegQuality = (quality * 100).clamp(1, 100).toInt();
      final compressedBytes = img.encodeJpg(decoded, quality: jpegQuality);

      _progress = 0.85;
      notifyListeners();

      // Write compressed file alongside the original.
      final compressedFile = File('${file.path}.compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      final compressedSize = compressedBytes.length;

      _progress = 1.0;
      _isCompressing = false;
      notifyListeners();

      return CompressResult(
        originalSize: originalSize,
        compressedSize: compressedSize,
        savedBytes: originalSize - compressedSize,
        outputPath: compressedFile.path,
      );
    } catch (e) {
      _isCompressing = false;
      _progress = 0.0;
      notifyListeners();
      rethrow;
    }
  }

  // -----------------------------------------------------------------------
  // Video compression
  // -----------------------------------------------------------------------

  /// Compress a video asset using the `video_compress` package.
  Future<CompressResult> compressVideo(String assetId) async {
    _isCompressing = true;
    _progress = 0.0;
    notifyListeners();

    try {
      final entity = await AssetEntity.fromId(assetId);
      if (entity == null) {
        throw Exception('Asset not found: $assetId');
      }

      final file = await entity.file;
      if (file == null) {
        throw Exception('Could not load file for asset: $assetId');
      }

      final originalSize = await file.length();

      // Listen to compression progress.
      VideoCompress.compressProgress$.subscribe((progress) {
        _progress = progress / 100.0;
        notifyListeners();
      });

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (info == null || info.file == null) {
        throw Exception('Video compression failed for asset: $assetId');
      }

      final compressedSize = await info.file!.length();

      _progress = 1.0;
      _isCompressing = false;
      notifyListeners();

      return CompressResult(
        originalSize: originalSize,
        compressedSize: compressedSize,
        savedBytes: originalSize - compressedSize,
        outputPath: info.file!.path,
      );
    } catch (e) {
      _isCompressing = false;
      _progress = 0.0;
      notifyListeners();
      rethrow;
    }
  }

  // -----------------------------------------------------------------------
  // Batch helpers
  // -----------------------------------------------------------------------

  /// Compress a list of photo assets and return aggregate results.
  Future<List<CompressResult>> compressPhotos(
    List<String> assetIds, {
    double quality = 0.6,
  }) async {
    final results = <CompressResult>[];
    for (var i = 0; i < assetIds.length; i++) {
      final result = await compressPhoto(assetIds[i], quality: quality);
      results.add(result);
    }
    return results;
  }

  /// Cancel any in-progress video compression.
  Future<void> cancelVideoCompression() async {
    await VideoCompress.cancelCompression();
    _isCompressing = false;
    _progress = 0.0;
    notifyListeners();
  }
}
