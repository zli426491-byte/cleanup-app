import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;

import '../analytics/analytics_manager.dart';
import 'image_quality_service.dart';

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
  final bool isScreenshot;
  final bool isBlurry;
  final bool isDark;
  final bool isOverexposed;

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
    this.isScreenshot = false,
    this.isBlurry = false,
    this.isDark = false,
    this.isOverexposed = false,
  });

  PhotoAsset copyWith({
    String? hash,
    Uint8List? thumbnail,
    bool? isScreenshot,
    bool? isBlurry,
    bool? isDark,
    bool? isOverexposed,
  }) {
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
      isScreenshot: isScreenshot ?? this.isScreenshot,
      isBlurry: isBlurry ?? this.isBlurry,
      isDark: isDark ?? this.isDark,
      isOverexposed: isOverexposed ?? this.isOverexposed,
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
  final List<PhotoAsset> blurryPhotos;
  final List<PhotoAsset> darkPhotos;
  final List<PhotoAsset> overexposedPhotos;
  final int totalSavingsEstimate;

  const ScanResult({
    required this.allAssets,
    required this.duplicateGroups,
    required this.similarGroups,
    required this.screenshots,
    required this.largeFiles,
    required this.videos,
    required this.blurryPhotos,
    required this.darkPhotos,
    required this.overexposedPhotos,
    required this.totalSavingsEstimate,
  });

  static const empty = ScanResult(
    allAssets: [],
    duplicateGroups: [],
    similarGroups: [],
    screenshots: [],
    largeFiles: [],
    videos: [],
    blurryPhotos: [],
    darkPhotos: [],
    overexposedPhotos: [],
    totalSavingsEstimate: 0,
  );
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class PhotoScannerService extends ChangeNotifier {
  static const _assetPageSize = 250;
  static const _maxAssetsToScan = 2500;
  static const _maxScreenshotAssetsToScan = 800;
  static const _enableInlineImageAnalysis = true;
  static const _maxImagesToAnalyze = 1200;
  static const _maxScreenshotsToAnalyze = 350;
  static const _thumbnailTimeout = Duration(milliseconds: 350);
  static const _assetPageTimeout = Duration(seconds: 4);
  static const _imageAnalysisBudget = Duration(seconds: 24);
  static const _iosScreenshotMediaSubtype = 1 << 2;

  bool _isScanning = false;
  double _scanProgress = 0.0;
  ScanPhase _currentPhase = ScanPhase.idle;
  ScanResult _scanResult = ScanResult.empty;
  String? _lastError;

  bool get isScanning => _isScanning;
  double get scanProgress => _scanProgress;
  ScanPhase get currentPhase => _currentPhase;
  ScanResult get scanResult => _scanResult;
  String? get lastError => _lastError;

  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  /// Run a full device scan: fetch assets, hash, find duplicates/similar,
  /// screenshots, large files, and videos.
  Future<void> startFullScan() async {
    AnalyticsManager.instance.track(AnalyticsEvent.scanStarted.name);
    _isScanning = true;
    _scanProgress = 0.0;
    _currentPhase = ScanPhase.fetchingAssets;
    _lastError = null;
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
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(needTitle: true),
          videoOption: const FilterOption(needTitle: true),
        ),
      );
      if (albums.isEmpty) {
        _reset();
        return;
      }

      // Scan the primary "All/Recent" library first. Walking every album on a
      // large phone creates many duplicate reads and can look frozen.
      final scanAlbums = _primaryScanAlbums(albums);

      final List<AssetEntity> rawAssets = [];
      final Set<String> screenshotIds = {};
      for (final album in scanAlbums) {
        final isScreenshotAlbum = _isScreenshotAlbum(album);
        final count = await album.assetCountAsync.timeout(
          _assetPageTimeout,
          onTimeout: () => 0,
        );
        final maxForAlbum =
            isScreenshotAlbum ? _maxScreenshotAssetsToScan : _maxAssetsToScan;
        final cappedCount =
            count > maxForAlbum ? maxForAlbum : count;

        for (var start = 0; start < cappedCount; start += _assetPageSize) {
          final end = (start + _assetPageSize > cappedCount)
              ? cappedCount
              : start + _assetPageSize;
          final assets = await album.getAssetListRange(
            start: start,
            end: end,
          ).timeout(
            _assetPageTimeout,
            onTimeout: () => const <AssetEntity>[],
          );
          rawAssets.addAll(assets);
          if (isScreenshotAlbum) {
            screenshotIds.addAll(assets.map((asset) => asset.id));
          }

          _scanProgress =
              0.02 + 0.08 * (end / cappedCount.clamp(1, _maxAssetsToScan));
          notifyListeners();
          await Future<void>.delayed(Duration.zero);

          if (rawAssets.length >= _maxAssetsToScan + _maxScreenshotAssetsToScan) {
            break;
          }
        }
        if (!isScreenshotAlbum &&
            rawAssets.length >= _maxAssetsToScan + _maxScreenshotAssetsToScan) {
          break;
        }
      }

      // Deduplicate by id (asset may appear in multiple albums).
      final Map<String, AssetEntity> uniqueMap = {};
      for (final a in rawAssets) {
        uniqueMap[a.id] = a;
      }
      final sortedAssets = uniqueMap.values.toList()
        ..sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      final selectedAssets = <String, AssetEntity>{};
      for (final asset in sortedAssets) {
        if (screenshotIds.contains(asset.id) || _isScreenshotEntity(asset)) {
          selectedAssets[asset.id] = asset;
          if (selectedAssets.length >= _maxScreenshotAssetsToScan) break;
        }
      }
      for (final asset in sortedAssets) {
        if (selectedAssets.length >= _maxAssetsToScan + _maxScreenshotAssetsToScan) {
          break;
        }
        selectedAssets[asset.id] = asset;
      }
      final uniqueAssets = selectedAssets.values.toList()
        ..sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      _scanProgress = 0.10;
      notifyListeners();

      // 2. Convert to PhotoAsset quickly. Deep image analysis is kept out of
      // the main scan because PhotoKit thumbnail reads can stall on large or
      // iCloud-backed libraries.
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
          isScreenshot:
              screenshotIds.contains(entity.id) || _isScreenshotEntity(entity),
        );
      }).toList();

      _scanProgress = 0.20;
      notifyListeners();

      if (_enableInlineImageAnalysis) {
        final analysisIndexes = <int>[];
        var screenshotAnalysisCount = 0;
        for (var i = 0; i < photoAssets.length; i++) {
          if (photoAssets[i].type == AssetType.image &&
              photoAssets[i].isScreenshot) {
            analysisIndexes.add(i);
            screenshotAnalysisCount++;
            if (screenshotAnalysisCount >= _maxScreenshotsToAnalyze) break;
            if (analysisIndexes.length >= _maxImagesToAnalyze) break;
          }
        }
        if (analysisIndexes.length < _maxImagesToAnalyze) {
          for (var i = 0; i < photoAssets.length; i++) {
            if (photoAssets[i].type != AssetType.image ||
                photoAssets[i].isScreenshot ||
                analysisIndexes.contains(i)) {
              continue;
            }
            analysisIndexes.add(i);
            if (analysisIndexes.length >= _maxImagesToAnalyze) break;
          }
        }

        if (analysisIndexes.isNotEmpty) {
          final analysisWatch = Stopwatch()..start();
          for (var position = 0; position < analysisIndexes.length; position++) {
            if (analysisWatch.elapsed >= _imageAnalysisBudget) break;
            final idx = analysisIndexes[position];
            final entity = uniqueAssets[idx];
            final analysis = await _analyzeImage(entity).timeout(
              _thumbnailTimeout,
              onTimeout: () => null,
            );
            if (analysis != null) {
              photoAssets[idx] = photoAssets[idx].copyWith(
                hash: analysis.hash,
                thumbnail: analysis.thumbnail,
                isBlurry: analysis.quality.isBlurry,
                isDark: analysis.quality.isDark,
                isOverexposed: analysis.quality.isOverexposed,
              );
            }

            _scanProgress =
                0.20 + 0.30 * ((position + 1) / analysisIndexes.length);
            notifyListeners();
            await Future<void>.delayed(Duration.zero);
          }
        }
      }

      _scanProgress = 0.45;
      notifyListeners();
      await Future<void>.delayed(Duration.zero);

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

      final blurryPhotos = photoAssets.where((a) => a.isBlurry).toList();
      final darkPhotos = photoAssets.where((a) => a.isDark).toList();
      final overexposedPhotos = photoAssets.where((a) => a.isOverexposed).toList();

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
        blurryPhotos: blurryPhotos,
        darkPhotos: darkPhotos,
        overexposedPhotos: overexposedPhotos,
        totalSavingsEstimate: totalSavings,
      );

      _currentPhase = ScanPhase.done;
      _scanProgress = 1.0;
      _isScanning = false;
      AnalyticsManager.instance.track(
        AnalyticsEvent.scanCompleted.name,
        properties: {
          'assets': photoAssets.length,
          'duplicates': duplicateGroups.length,
          'similar_groups': similarGroups.length,
          'screenshots': screenshots.length,
          'large_files': largeFiles.length,
          'videos': videos.length,
          'blurry_photos': blurryPhotos.length,
          'dark_photos': darkPhotos.length,
          'estimated_savings_mb': (totalSavings / 1048576).round(),
        },
      );
      notifyListeners();
    } catch (e) {
      debugPrint('PhotoScannerService.startFullScan error: $e');
      _lastError = '掃描中斷，請確認照片權限後再試一次。';
      _reset(keepError: true);
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
        final remainingAssets =
            _scanResult.allAssets.where((a) => !deletedIds.contains(a.id)).toList();
        final duplicateGroups =
            _filterDuplicateGroups(_scanResult.duplicateGroups, deletedIds);
        final similarGroups =
            _filterSimilarGroups(_scanResult.similarGroups, deletedIds);
        final screenshots =
            _scanResult.screenshots.where((a) => !deletedIds.contains(a.id)).toList();
        final largeFiles =
            _scanResult.largeFiles.where((a) => !deletedIds.contains(a.id)).toList();
        final videos =
            _scanResult.videos.where((a) => !deletedIds.contains(a.id)).toList();
        final blurryPhotos =
            _scanResult.blurryPhotos.where((a) => !deletedIds.contains(a.id)).toList();
        final darkPhotos =
            _scanResult.darkPhotos.where((a) => !deletedIds.contains(a.id)).toList();
        final overexposedPhotos =
            _scanResult.overexposedPhotos.where((a) => !deletedIds.contains(a.id)).toList();

        _scanResult = ScanResult(
          allAssets: remainingAssets,
          duplicateGroups: duplicateGroups,
          similarGroups: similarGroups,
          screenshots: screenshots,
          largeFiles: largeFiles,
          videos: videos,
          blurryPhotos: blurryPhotos,
          darkPhotos: darkPhotos,
          overexposedPhotos: overexposedPhotos,
          totalSavingsEstimate: _estimateSavings(
            duplicateGroups: duplicateGroups,
            similarGroups: similarGroups,
            screenshots: screenshots,
            largeFiles: largeFiles,
          ),
        );
        AnalyticsManager.instance.track(
          AnalyticsEvent.photosDeleted.name,
          properties: {'count': result.length},
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

  /// Build the thumbnail used by the UI, the dHash used by duplicate
  /// detection, and lightweight quality flags in one thumbnail read.
  Future<_ImageAnalysis?> _analyzeImage(AssetEntity entity) async {
    try {
      final thumbData = await entity.thumbnailDataWithSize(
        const ThumbnailSize(160, 160),
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

      return _ImageAnalysis(
        hash: hash.toRadixString(16).padLeft(16, '0'),
        thumbnail: thumbData,
        quality: _analyzeQuality(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  ImageQuality _analyzeQuality(img.Image image) {
    final resized = img.copyResize(img.grayscale(image), width: 96);
    double brightnessTotal = 0;
    double laplacianTotal = 0;
    double laplacianTotalSq = 0;
    var count = 0;

    for (var y = 1; y < resized.height - 1; y++) {
      for (var x = 1; x < resized.width - 1; x++) {
        final center = resized.getPixel(x, y).luminanceNormalized;
        final top = resized.getPixel(x, y - 1).luminanceNormalized;
        final bottom = resized.getPixel(x, y + 1).luminanceNormalized;
        final left = resized.getPixel(x - 1, y).luminanceNormalized;
        final right = resized.getPixel(x + 1, y).luminanceNormalized;
        final laplacian = -4 * center + top + bottom + left + right;

        brightnessTotal += center;
        laplacianTotal += laplacian;
        laplacianTotalSq += laplacian * laplacian;
        count++;
      }
    }

    final brightness = count == 0 ? 0.5 : brightnessTotal / count;
    final mean = count == 0 ? 0.0 : laplacianTotal / count;
    final blurScore = count == 0
        ? 999.0
        : ((laplacianTotalSq / count) - (mean * mean)).abs() * 100000;

    final issues = <QualityIssue>[];
    if (blurScore < 120) issues.add(QualityIssue.blurry);
    if (brightness < 0.15) issues.add(QualityIssue.tooDark);
    if (brightness > 0.85) issues.add(QualityIssue.overexposed);

    return ImageQuality(
      blurScore: blurScore,
      brightness: brightness,
      issues: issues,
    );
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
      final entity = entityMap[a.id];
      return a.isScreenshot || (entity != null && _isScreenshotEntity(entity));
    }).toList();
  }

  List<AssetPathEntity> _primaryScanAlbums(List<AssetPathEntity> albums) {
    final selected = <String, AssetPathEntity>{};
    for (final album in albums.where(_isScreenshotAlbum)) {
      selected[album.id] = album;
    }
    final allAlbums = albums.where((album) => album.isAll).toList();
    if (allAlbums.isNotEmpty) {
      selected[allAlbums.first.id] = allAlbums.first;
    } else {
      selected[albums.first.id] = albums.first;
    }
    return selected.values.toList();
  }

  bool _isScreenshotAlbum(AssetPathEntity album) {
    final name = album.name.toLowerCase();
    return name.contains('screenshot') ||
        name.contains('screen shot') ||
        name.contains('screen_shot') ||
        name.contains('截圖') ||
        name.contains('螢幕快照') ||
        album.albumTypeEx?.darwin?.subtype ==
            PMDarwinAssetCollectionSubtype.smartAlbumScreenshots;
  }

  bool _isScreenshotEntity(AssetEntity entity) {
    final title = (entity.title ?? '').toLowerCase();
    return entity.type == AssetType.image &&
        ((entity.subtype & _iosScreenshotMediaSubtype) ==
                _iosScreenshotMediaSubtype ||
            title.contains('screenshot') ||
            title.contains('screen shot') ||
            title.contains('screen_shot') ||
            title.contains('截圖') ||
            title.contains('螢幕快照'));
  }

  List<DuplicateGroup> _filterDuplicateGroups(
    List<DuplicateGroup> groups,
    Set<String> deletedIds,
  ) {
    return groups
        .map((group) => DuplicateGroup(
              hash: group.hash,
              assets: group.assets.where((a) => !deletedIds.contains(a.id)).toList(),
            ))
        .where((group) => group.assets.length > 1)
        .toList();
  }

  List<SimilarGroup> _filterSimilarGroups(
    List<SimilarGroup> groups,
    Set<String> deletedIds,
  ) {
    return groups
        .map((group) => SimilarGroup(
              assets: group.assets.where((a) => !deletedIds.contains(a.id)).toList(),
              hammingDistance: group.hammingDistance,
            ))
        .where((group) => group.assets.length > 1)
        .toList();
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

  void _reset({bool keepError = false}) {
    _isScanning = false;
    _scanProgress = 0.0;
    _currentPhase = ScanPhase.idle;
    if (!keepError) _lastError = null;
    notifyListeners();
  }
}

class _ImageAnalysis {
  final String hash;
  final Uint8List thumbnail;
  final ImageQuality quality;

  const _ImageAnalysis({
    required this.hash,
    required this.thumbnail,
    required this.quality,
  });
}
