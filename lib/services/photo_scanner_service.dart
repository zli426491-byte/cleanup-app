import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../analytics/analytics_manager.dart';

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
  static const _assetPageSize = 120;
  static const _maxAssetsToScan = 900;
  static const _maxScreenshotAssetsToScan = 300;
  static const _assetPageTimeout = Duration(seconds: 2);
  static const _mainScanWatchdog = Duration(seconds: 10);
  static const _iosScreenshotMediaSubtype = 1 << 2;

  bool _isScanning = false;
  double _scanProgress = 0.0;
  ScanPhase _currentPhase = ScanPhase.idle;
  ScanResult _scanResult = ScanResult.empty;
  String? _lastError;
  int _scanRunId = 0;

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
    final runId = ++_scanRunId;
    _scanProgress = 0.0;
    _currentPhase = ScanPhase.fetchingAssets;
    _lastError = null;
    notifyListeners();

    final rawAssets = <AssetEntity>[];
    final screenshotIds = <String>{};
    var timedOut = false;

    try {
      final result = await Future.any<ScanResult>([
        _runQuickIndexScan(
          runId: runId,
          rawAssets: rawAssets,
          screenshotIds: screenshotIds,
        ),
        Future<ScanResult>.delayed(_mainScanWatchdog, () {
          timedOut = true;
          return _buildQuickResult(
            rawAssets: rawAssets,
            screenshotIds: screenshotIds,
          );
        }),
      ]);

      if (!_isActiveScan(runId)) return;
      _finishScanResult(result, timedOut: timedOut);
    } catch (e) {
      if (!_isActiveScan(runId)) return;
      debugPrint('PhotoScannerService.startFullScan error: $e');
      _lastError = '掃描中斷，已用安全模式完成。';
      _finishScanResult(
        _buildQuickResult(rawAssets: rawAssets, screenshotIds: screenshotIds),
        timedOut: true,
      );
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
        final remainingAssets = _scanResult.allAssets
            .where((a) => !deletedIds.contains(a.id))
            .toList();
        final duplicateGroups = _filterDuplicateGroups(
          _scanResult.duplicateGroups,
          deletedIds,
        );
        final similarGroups = _filterSimilarGroups(
          _scanResult.similarGroups,
          deletedIds,
        );
        final screenshots = _scanResult.screenshots
            .where((a) => !deletedIds.contains(a.id))
            .toList();
        final largeFiles = _scanResult.largeFiles
            .where((a) => !deletedIds.contains(a.id))
            .toList();
        final videos = _scanResult.videos
            .where((a) => !deletedIds.contains(a.id))
            .toList();
        final blurryPhotos = _scanResult.blurryPhotos
            .where((a) => !deletedIds.contains(a.id))
            .toList();
        final darkPhotos = _scanResult.darkPhotos
            .where((a) => !deletedIds.contains(a.id))
            .toList();
        final overexposedPhotos = _scanResult.overexposedPhotos
            .where((a) => !deletedIds.contains(a.id))
            .toList();

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

  List<PhotoAsset> _collectScreenshots(
    List<PhotoAsset> assets,
    Map<String, AssetEntity> entityMap,
  ) {
    return assets.where((a) {
      final entity = entityMap[a.id];
      return a.isScreenshot || (entity != null && _isScreenshotEntity(entity));
    }).toList();
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
        .map(
          (group) => DuplicateGroup(
            hash: group.hash,
            assets: group.assets
                .where((a) => !deletedIds.contains(a.id))
                .toList(),
          ),
        )
        .where((group) => group.assets.length > 1)
        .toList();
  }

  List<SimilarGroup> _filterSimilarGroups(
    List<SimilarGroup> groups,
    Set<String> deletedIds,
  ) {
    return groups
        .map(
          (group) => SimilarGroup(
            assets: group.assets
                .where((a) => !deletedIds.contains(a.id))
                .toList(),
            hammingDistance: group.hammingDistance,
          ),
        )
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

    // Similar groups are review-first suggestions; estimate savings by keeping
    // the newest item in each group.
    for (final group in similarGroups) {
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

  Future<ScanResult> _runQuickIndexScan({
    required int runId,
    required List<AssetEntity> rawAssets,
    required Set<String> screenshotIds,
  }) async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!_isActiveScan(runId) || !permitted.isAuth) {
      return _buildQuickResult(
        rawAssets: rawAssets,
        screenshotIds: screenshotIds,
      );
    }

    _scanProgress = 0.08;
    notifyListeners();

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(needTitle: false),
        videoOption: const FilterOption(needTitle: false),
      ),
    ).timeout(_assetPageTimeout, onTimeout: () => const <AssetPathEntity>[]);
    if (!_isActiveScan(runId) || albums.isEmpty) {
      return _buildQuickResult(
        rawAssets: rawAssets,
        screenshotIds: screenshotIds,
      );
    }

    final allAlbums = albums.where((album) => album.isAll).toList();
    final allAlbum = allAlbums.isNotEmpty ? allAlbums.first : albums.first;
    final count = await allAlbum.assetCountAsync.timeout(
      _assetPageTimeout,
      onTimeout: () => 0,
    );
    if (!_isActiveScan(runId) || count <= 0) {
      return _buildQuickResult(
        rawAssets: rawAssets,
        screenshotIds: screenshotIds,
      );
    }

    final cappedCount = count > _maxAssetsToScan ? _maxAssetsToScan : count;
    for (var start = 0; start < cappedCount; start += _assetPageSize) {
      if (!_isActiveScan(runId)) break;
      final end = (start + _assetPageSize > cappedCount)
          ? cappedCount
          : start + _assetPageSize;
      final assets = await allAlbum
          .getAssetListRange(start: start, end: end)
          .timeout(_assetPageTimeout, onTimeout: () => const <AssetEntity>[]);
      if (!_isActiveScan(runId)) break;

      rawAssets.addAll(assets);
      _scanProgress = 0.10 + 0.62 * (end / cappedCount);
      notifyListeners();
      await Future<void>.delayed(Duration.zero);
    }

    _currentPhase = ScanPhase.collectingScreenshots;
    _scanProgress = 0.78;
    notifyListeners();
    final result = _buildQuickResult(
      rawAssets: rawAssets,
      screenshotIds: screenshotIds,
    );

    _currentPhase = ScanPhase.findingLargeFiles;
    _scanProgress = 0.90;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);

    return result;
  }

  bool _isActiveScan(int runId) => _isScanning && _scanRunId == runId;

  ScanResult _buildQuickResult({
    required List<AssetEntity> rawAssets,
    required Set<String> screenshotIds,
  }) {
    final uniqueMap = <String, AssetEntity>{};
    for (final asset in rawAssets) {
      uniqueMap[asset.id] = asset;
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
      if (selectedAssets.length >=
          _maxAssetsToScan + _maxScreenshotAssetsToScan) {
        break;
      }
      selectedAssets[asset.id] = asset;
    }

    final photoAssets = selectedAssets.values.map((entity) {
      final estimatedSize = entity.width * entity.height * 3;
      return PhotoAsset(
        id: entity.id,
        title: entity.title,
        width: entity.width,
        height: entity.height,
        size: estimatedSize,
        createDate: entity.createDateTime,
        type: entity.type,
        isScreenshot:
            screenshotIds.contains(entity.id) || _isScreenshotEntity(entity),
      );
    }).toList();

    final screenshots = _collectScreenshots(photoAssets, uniqueMap);
    const largeThreshold = 5 * 1024 * 1024;
    final largeFiles =
        photoAssets.where((a) => a.size > largeThreshold).toList()
          ..sort((a, b) => b.size.compareTo(a.size));
    final videos = photoAssets.where((a) => a.type == AssetType.video).toList()
      ..sort((a, b) => b.size.compareTo(a.size));
    final duplicateGroups = _findMetadataDuplicates(photoAssets);
    final duplicateIds = duplicateGroups
        .expand((group) => group.assets.map((asset) => asset.id))
        .toSet();
    final similarGroups = _findMetadataSimilar(photoAssets, duplicateIds);

    return ScanResult(
      allAssets: photoAssets,
      duplicateGroups: duplicateGroups,
      similarGroups: similarGroups,
      screenshots: screenshots,
      largeFiles: largeFiles,
      videos: videos,
      blurryPhotos: const [],
      darkPhotos: const [],
      overexposedPhotos: const [],
      totalSavingsEstimate: _estimateSavings(
        duplicateGroups: duplicateGroups,
        similarGroups: similarGroups,
        screenshots: screenshots,
        largeFiles: largeFiles,
      ),
    );
  }

  List<DuplicateGroup> _findMetadataDuplicates(List<PhotoAsset> assets) {
    const timeBucket = Duration(seconds: 2);
    final buckets = <String, List<PhotoAsset>>{};

    for (final asset in assets) {
      if (asset.type != AssetType.image ||
          asset.width <= 0 ||
          asset.height <= 0) {
        continue;
      }

      final normalizedWidth = math.max(asset.width, asset.height);
      final normalizedHeight = math.min(asset.width, asset.height);
      final createdBucket =
          asset.createDate.millisecondsSinceEpoch ~/ timeBucket.inMilliseconds;
      final title = (asset.title ?? '').trim().toLowerCase();
      final key = title.isEmpty
          ? 'time:$normalizedWidth:$normalizedHeight:$createdBucket'
          : 'title:$normalizedWidth:$normalizedHeight:$title';
      buckets.putIfAbsent(key, () => <PhotoAsset>[]).add(asset);
    }

    final groups = <DuplicateGroup>[];
    for (final entry in buckets.entries) {
      if (entry.value.length < 2) continue;
      final grouped = List<PhotoAsset>.from(entry.value)
        ..sort((a, b) => b.createDate.compareTo(a.createDate));
      groups.add(DuplicateGroup(hash: entry.key, assets: grouped));
    }

    groups.sort((a, b) => b.assets.length.compareTo(a.assets.length));
    return groups.take(40).toList();
  }

  List<SimilarGroup> _findMetadataSimilar(
    List<PhotoAsset> assets,
    Set<String> excludedIds,
  ) {
    final images =
        assets
            .where(
              (asset) =>
                  asset.type == AssetType.image &&
                  asset.width > 0 &&
                  asset.height > 0 &&
                  !asset.isScreenshot &&
                  !excludedIds.contains(asset.id),
            )
            .toList()
          ..sort((a, b) => b.createDate.compareTo(a.createDate));

    final usedIds = <String>{};
    final groups = <SimilarGroup>[];
    for (var i = 0; i < images.length; i++) {
      final base = images[i];
      if (usedIds.contains(base.id)) continue;

      final group = <PhotoAsset>[base];
      final compareEnd = math.min(images.length, i + 28);
      for (var j = i + 1; j < compareEnd && group.length < 8; j++) {
        final candidate = images[j];
        if (usedIds.contains(candidate.id)) continue;
        if (_isMetadataSimilar(base, candidate)) {
          group.add(candidate);
        }
      }

      if (group.length > 1) {
        for (final asset in group) {
          usedIds.add(asset.id);
        }
        groups.add(SimilarGroup(assets: group, hammingDistance: 0));
        if (groups.length >= 40) break;
      }
    }

    groups.sort((a, b) => b.assets.length.compareTo(a.assets.length));
    return groups;
  }

  bool _isMetadataSimilar(PhotoAsset a, PhotoAsset b) {
    final timeGap = a.createDate.difference(b.createDate).abs();
    if (timeGap > const Duration(hours: 4)) return false;

    final aspectA = _aspectRatio(a);
    final aspectB = _aspectRatio(b);
    if ((aspectA - aspectB).abs() > 0.045) return false;

    final widthA = math.max(a.width, a.height);
    final widthB = math.max(b.width, b.height);
    final heightA = math.min(a.width, a.height);
    final heightB = math.min(b.width, b.height);
    final widthDelta = (widthA - widthB).abs() / math.max(widthA, widthB);
    final heightDelta = (heightA - heightB).abs() / math.max(heightA, heightB);

    return widthDelta <= 0.20 && heightDelta <= 0.20;
  }

  double _aspectRatio(PhotoAsset asset) {
    final longSide = math.max(asset.width, asset.height);
    final shortSide = math.min(asset.width, asset.height);
    if (shortSide <= 0) return 0;
    return longSide / shortSide;
  }

  void _finishScanResult(ScanResult result, {bool timedOut = false}) {
    _scanResult = result;
    _currentPhase = ScanPhase.done;
    _scanProgress = 1.0;
    _isScanning = false;
    _lastError = timedOut ? '掃描已先完成，部分深度分析已略過。' : null;
    AnalyticsManager.instance.track(
      AnalyticsEvent.scanCompleted.name,
      properties: {
        'assets': result.allAssets.length,
        'duplicates': result.duplicateGroups.length,
        'similar_groups': result.similarGroups.length,
        'screenshots': result.screenshots.length,
        'large_files': result.largeFiles.length,
        'videos': result.videos.length,
        'blurry_photos': result.blurryPhotos.length,
        'dark_photos': result.darkPhotos.length,
        'timed_out': timedOut,
        'estimated_savings_mb': (result.totalSavingsEstimate / 1048576).round(),
      },
    );
    notifyListeners();
  }
}
