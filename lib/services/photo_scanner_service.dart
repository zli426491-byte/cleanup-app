import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;

// ---------------------------------------------------------------------------
// Inline models (move to ../models/ when those files are created)
// ---------------------------------------------------------------------------

enum ScanPhase {
  idle,
  fetchingAssets,
  computingHashes,
  findingDuplicates,
  findingSimilar,
  collectingScreenshots,
  findingLargeFiles,
  scanningVideos,
  done,
}

class PhotoAsset {
  final String id;
  final String? title;
  final int width;
  final int height;
  final int size; // bytes
  final DateTime createDate;
  final AssetType type;
  final Uint8List? thumbnail;
  final String? hash;

  const PhotoAsset({
    required this.id,
    this.title,
    required this.width,
    required this.height,
    required this.size,
    required this.createDate,
    required this.type,
    this.thumbnail,
    this.hash,
  });

  PhotoAsset copyWith({String? hash, Uint8List? thumbnail}) {
    return PhotoAsset(
      id: id,
      title: title,
      width: width,
      height: height,
      size: size,
      createDate: createDate,
      type: type,
      thumbnail: thumbnail ?? this.thumbnail,
      hash: hash ?? this.hash,
    );
  }
}

class DuplicateGroup {
  final String hash;
  final List<PhotoAsset> assets;

  const DuplicateGroup({required this.hash, required this.assets});
}

class SimilarGroup {
  final List<PhotoAsset> assets;
  final int hammingDistance;

  const SimilarGroup({required this.assets, required this.hammingDistance});
}

class ScanResult {
  final List<PhotoAsset> allAssets;
  final List<DuplicateGroup> duplicateGroups;
  final List<SimilarGroup> similarGroups;
  final List<PhotoAsset> screenshots;
  final List<PhotoAsset> largeFiles;
  final List<PhotoAsset> videos;
  final int totalSavingsEstimate;

  const ScanResult({
    required this.allAssets,
    required this.duplicateGroups,
    required this.similarGroups,
    required this.screenshots,
    required this.largeFiles,
    required this.videos,
    required this.totalSavingsEstimate,
  });

  static const empty = ScanResult(
    allAssets: [],
    duplicateGroups: [],
    similarGroups: [],
    screenshots: [],
    largeFiles: [],
    videos: [],
    totalSavingsEstimate: 0,
  );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class PhotoScannerService extends ChangeNotifier {
  bool _isScanning = false;
  double _scanProgress = 0.0;
  ScanPhase _currentPhase = ScanPhase.idle;
  ScanResult _scanResult = ScanResult.empty;

  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  ScanPhase get currentPhase => _currentPhase;
  ScanResult get scanResult => _scanResult;

  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  /// Run a full device scan: fetch assets, hash, find duplicates/similar,
  /// screenshots, large files, and videos.
  Future<void> startFullScan() async {
    _isScanning = true;
    _scanProgress = 0.0;
    _currentPhase = ScanPhase.fetchingAssets;
    notifyListeners();

    try {
      // 1. Request permission & fetch all assets
      final permitted = await PhotoManager.requestPermissionExtend();
      if (!permitted.isAuth) {
        _reset();
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // photos + videos
      );
      if (albums.isEmpty) {
        _reset();
        return;
      }

      // Gather every asset across albums.
      final List<AssetEntity> rawAssets = [];
      for (final album in albums) {
        final count = await album.assetCountAsync;
        final assets = await album.getAssetListRange(start: 0, end: count);
        rawAssets.addAll(assets);
      }

      // Deduplicate by id (asset may appear in multiple albums).
      final Map<String, AssetEntity> uniqueMap = {};
      for (final a in rawAssets) {
        uniqueMap[a.id] = a;
      }
      final uniqueAssets = uniqueMap.values.toList();

      _scanProgress = 0.10;
      notifyListeners();

      // 2. Convert to PhotoAsset & compute perceptual hashes (batched)
      _currentPhase = ScanPhase.computingHashes;
      notifyListeners();

      // First pass: create PhotoAssets quickly without file I/O
      final List<PhotoAsset> photoAssets = uniqueAssets.map((entity) {
        // Estimate size from dimensions (avoid slow file I/O)
        final estimatedSize = entity.width * entity.height * 3; // ~3 bytes/pixel
        return PhotoAsset(
          id: entity.id,
          title: entity.title,
          width: entity.width,
          height: entity.height,
          size: estimatedSize,
          createDate: entity.createDateTime,
          type: entity.type,
          hash: null,
        );
      }).toList();

      _scanProgress = 0.20;
      notifyListeners();

      // Second pass: compute hashes only for images, in batches
      const batchSize = 50;
      for (var i = 0; i < photoAssets.length; i += batchSize) {
        final end = (i + batchSize > photoAssets.length)
            ? photoAssets.length
            : i + batchSize;

        await Future.wait(
          List.generate(end - i, (j) async {
            final idx = i + j;
            if (photoAssets[idx].type == AssetType.image) {
              final entity = uniqueAssets[idx];
              final hash = await _computeDHash(entity);
              if (hash != null) {
                photoAssets[idx] = photoAssets[idx].copyWith(hash: hash);
              }
            }
          }),
        );

        _scanProgress = 0.20 + 0.30 * ((i + batchSize).clamp(0, photoAssets.length) / photoAssets.length);
        notifyListeners();
        await Future.delayed(Duration.zero);
      }

      // 3. Find exact duplicates (identical hash)
      _currentPhase = ScanPhase.findingDuplicates;
      _scanProgress = 0.55;
      notifyListeners();

      final duplicateGroups = _findDuplicates(photoAssets);

      // 4. Find similar images (hamming distance ≤ 12)
      _currentPhase = ScanPhase.findingSimilar;
      _scanProgress = 0.65;
      notifyListeners();

      final similarGroups = _findSimilar(photoAssets, threshold: 12);

      // 5. Collect screenshots
      _currentPhase = ScanPhase.collectingScreenshots;
      _scanProgress = 0.75;
      notifyListeners();

      final screenshots = _collectScreenshots(photoAssets, uniqueMap);

      // 6. Large files (> 5 MB)
      _currentPhase = ScanPhase.findingLargeFiles;
      _scanProgress = 0.85;
      notifyListeners();

      const largeThreshold = 5 * 1024 * 1024; // 5 MB
      final largeFiles =
          photoAssets.where((a) => a.size > largeThreshold).toList()
            ..sort((a, b) => b.size.compareTo(a.size));

      // 7. Videos
      _currentPhase = ScanPhase.scanningVideos;
      _scanProgress = 0.93;
      notifyListeners();

      final videos =
          photoAssets.where((a) => a.type == AssetType.video).toList()
            ..sort((a, b) => b.size.compareTo(a.size));

      // Build result
      final totalSavings = _estimateSavings(
        duplicateGroups: duplicateGroups,
        similarGroups: similarGroups,
        screenshots: screenshots,
        largeFiles: largeFiles,
      );

      _scanResult = ScanResult(
        allAssets: photoAssets,
        duplicateGroups: duplicateGroups,
        similarGroups: similarGroups,
        screenshots: screenshots,
        largeFiles: largeFiles,
        videos: videos,
        totalSavingsEstimate: totalSavings,
      );

      _currentPhase = ScanPhase.done;
      _scanProgress = 1.0;
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint('PhotoScannerService.startFullScan error: $e');
      _reset();
    }
  }

  /// Delete a list of assets from the device.
  Future<bool> deleteAssets(List<PhotoAsset> assets) async {
    try {
      final ids = assets.map((a) => a.id).toList();
      final result = await PhotoManager.editor.deleteWithIds(ids);
      if (result.isNotEmpty) {
        // Remove deleted assets from the current scan result.
        final deletedIds = result.toSet();
        _scanResult = ScanResult(
          allAssets:
              _scanResult.allAssets.where((a) => !deletedIds.contains(a.id)).toList(),
          duplicateGroups: _scanResult.duplicateGroups,
          similarGroups: _scanResult.similarGroups,
          screenshots:
              _scanResult.screenshots.where((a) => !deletedIds.contains(a.id)).toList(),
          largeFiles:
              _scanResult.largeFiles.where((a) => !deletedIds.contains(a.id)).toList(),
          videos:
              _scanResult.videos.where((a) => !deletedIds.contains(a.id)).toList(),
          totalSavingsEstimate: _scanResult.totalSavingsEstimate,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('PhotoScannerService.deleteAssets error: $e');
      return false;
    }
  }

  // -----------------------------------------------------------------------
  // Perceptual hashing (dHash)
  // -----------------------------------------------------------------------

  /// Compute a 64-bit difference hash (dHash) for an image asset.
  ///
  /// Algorithm:
  ///   1. Resize to 9x8 grayscale.
  ///   2. For each row compare adjacent pixels (left < right → 1).
  ///   3. Produces an 8x8 = 64-bit hash.
  Future<String?> _computeDHash(AssetEntity entity) async {
    try {
      final thumbData = await entity.thumbnailDataWithSize(
        const ThumbnailSize(64, 64),
        format: ThumbnailFormat.jpeg,
      );
      if (thumbData == null) return null;

      final decoded = img.decodeImage(thumbData);
      if (decoded == null) return null;

      // Resize to 9 wide × 8 tall, grayscale.
      final resized = img.copyResize(decoded, width: 9, height: 8);
      final gray = img.grayscale(resized);

      int hash = 0;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final left = gray.getPixel(x, y).luminance;
          final right = gray.getPixel(x + 1, y).luminance;
          hash = (hash << 1) | (left < right ? 1 : 0);
        }
      }

      return hash.toRadixString(16).padLeft(16, '0');
    } catch (_) {
      return null;
    }
  }

  /// Hamming distance between two hex-encoded 64-bit hashes.
  static int _hammingDistance(String a, String b) {
    final valA = int.tryParse(a, radix: 16) ?? 0;
    final valB = int.tryParse(b, radix: 16) ?? 0;
    int xor = valA ^ valB;
    int count = 0;
    while (xor != 0) {
      count += xor & 1;
      xor >>= 1;
    }
    return count;
  }

  // -----------------------------------------------------------------------
  // Grouping helpers
  // -----------------------------------------------------------------------

  List<DuplicateGroup> _findDuplicates(List<PhotoAsset> assets) {
    final Map<String, List<PhotoAsset>> hashMap = {};
    for (final asset in assets) {
      if (asset.hash == null) continue;
      hashMap.putIfAbsent(asset.hash!, () => []).add(asset);
    }
    return hashMap.entries
        .where((e) => e.value.length > 1)
        .map((e) => DuplicateGroup(hash: e.key, assets: e.value))
        .toList();
  }

  List<SimilarGroup> _findSimilar(List<PhotoAsset> assets,
      {required int threshold}) {
    final hashed = assets.where((a) => a.hash != null).toList();
    final List<SimilarGroup> groups = [];
    final Set<String> visited = {};

    // Limit comparison to first 500 photos to avoid O(n²) freeze
    final limit = hashed.length > 500 ? 500 : hashed.length;

    for (var i = 0; i < limit; i++) {
      if (visited.contains(hashed[i].id)) continue;

      final List<PhotoAsset> group = [hashed[i]];
      int maxDist = 0;

      // Only compare nearby photos (within 100 index range) for performance
      final jEnd = (i + 100 > limit) ? limit : i + 100;
      for (var j = i + 1; j < jEnd; j++) {
        if (visited.contains(hashed[j].id)) continue;
        final dist = _hammingDistance(hashed[i].hash!, hashed[j].hash!);
        if (dist > 0 && dist <= threshold) {
          group.add(hashed[j]);
          if (dist > maxDist) maxDist = dist;
        }
      }

      if (group.length > 1) {
        for (final a in group) {
          visited.add(a.id);
        }
        groups.add(SimilarGroup(assets: group, hammingDistance: maxDist));
      }
    }

    return groups;
  }

  List<PhotoAsset> _collectScreenshots(
    List<PhotoAsset> assets,
    Map<String, AssetEntity> entityMap,
  ) {
    return assets.where((a) {
      final title = (a.title ?? '').toLowerCase();
      return title.contains('screenshot') || title.contains('screen_shot');
    }).toList();
  }

  int _estimateSavings({
    required List<DuplicateGroup> duplicateGroups,
    required List<SimilarGroup> similarGroups,
    required List<PhotoAsset> screenshots,
    required List<PhotoAsset> largeFiles,
  }) {
    int total = 0;

    // For duplicates, keep the first and remove the rest.
    for (final group in duplicateGroups) {
      for (var i = 1; i < group.assets.length; i++) {
        total += group.assets[i].size;
      }
    }

    // For large files, estimate 50 % compression savings.
    for (final f in largeFiles) {
      total += f.size ~/ 2;
    }

    return total;
  }

  // -----------------------------------------------------------------------
  // Internal helpers
  // -----------------------------------------------------------------------

  void _reset() {
    _isScanning = false;
    _scanProgress = 0.0;
    _currentPhase = ScanPhase.idle;
    notifyListeners();
  }
}
