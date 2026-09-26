import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../analytics/analytics_manager.dart';
import 'photo_content_analysis.dart';

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
  final bool sizeKnown;
  final bool analysisPending;
  final double? qualityScore;
  final List<String> qualityReasons;
  final String? pendingReason;
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
    this.sizeKnown = false,
    this.analysisPending = true,
    this.qualityScore,
    this.qualityReasons = const [],
    this.pendingReason,
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
    bool clearHash = false,
    int? size,
    bool? sizeKnown,
    bool? analysisPending,
    double? qualityScore,
    List<String>? qualityReasons,
    String? pendingReason,
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
      size: size ?? this.size,
      sizeKnown: sizeKnown ?? this.sizeKnown,
      analysisPending: analysisPending ?? this.analysisPending,
      qualityScore: qualityScore ?? this.qualityScore,
      qualityReasons: qualityReasons ?? this.qualityReasons,
      pendingReason: pendingReason ?? this.pendingReason,
      createDate: createDate,
      type: type,
      thumbnail: thumbnail ?? this.thumbnail,
      hash: clearHash ? null : hash ?? this.hash,
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
  final String? bestAssetId;
  final String? bestReason;

  const DuplicateGroup({
    required this.hash,
    required this.assets,
    this.bestAssetId,
    this.bestReason,
  });
}

class SimilarGroup {
  final List<PhotoAsset> assets;
  final int hammingDistance;
  final String? bestAssetId;
  final String? bestReason;

  const SimilarGroup({
    required this.assets,
    required this.hammingDistance,
    this.bestAssetId,
    this.bestReason,
  });
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

Map<String, Map<String, Object>> _analyzeThumbnailBatch(
  Map<String, Uint8List> bytes,
) => bytes.map((id, data) => MapEntry(id, analyzePhotoThumbnail(data).toMap()));

class _ScanCancelled implements Exception {}

class PhotoScannerService extends ChangeNotifier {
  static const _assetPageSize = 120;
  static const _pageTimeout = Duration(seconds: 30);
  static const _analysisTimeout = Duration(seconds: 65);
  static const _resourceChannel = MethodChannel('cleanup/photo_resources');
  static int _instances = 0;
  final String _instanceId = 'scanner-${++_instances}';
  bool _isScanning = false;
  bool _isDeleting = false;
  bool _disposed = false;
  bool _wasCancelled = false;
  bool _nativeAvailable;
  bool _hasCompletedScan = false;
  bool _hasLimitedAccess = false;
  int _scanRunId = 0;
  int _nextAssetOffset = 0;
  int? _availableAssetCount;
  double _scanProgress = 0;
  String? _lastError;
  ScanPhase _currentPhase = ScanPhase.idle;
  ScanResult _scanResult = ScanResult.empty;
  AssetPathEntity? _album;
  Completer<void>? _cancellation;
  final Map<String, AssetEntity> _entities = {};
  final Map<String, PhotoAsset> _assets = {};
  final Map<String, ContentSignature> _signatures = {};

  PhotoScannerService({bool? supportsNativeResources})
    : _nativeAvailable =
          supportsNativeResources ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  bool get isScanning => _isScanning;
  bool get isDeleting => _isDeleting;
  bool get wasCancelled => _wasCancelled;
  bool get hasCompletedScan => _hasCompletedScan;
  double get scanProgress => _scanProgress;
  ScanPhase get currentPhase => _currentPhase;
  ScanResult get scanResult => _scanResult;
  String? get lastError => _lastError;
  int? get availableAssetCount => _availableAssetCount;
  int get scannedAssetCount => _assets.length;
  int get analyzedAssetCount =>
      _assets.values.where((asset) => !asset.analysisPending).length;
  int get pendingAnalysisCount =>
      _assets.values.where((asset) => asset.analysisPending).length;
  String? get scanNotice {
    final notices = <String>[
      ?_lastError,
      if (_wasCancelled) '已暫停，已讀取與分析的結果已保留，可繼續掃描。',
      if (_availableAssetCount != null &&
          scannedAssetCount < _availableAssetCount!)
        '已讀取 $scannedAssetCount / $_availableAssetCount 個可存取項目。',
      if (_hasLimitedAccess) '僅整理你允許存取的照片，未讀取整個相簿。',
      if (!_isScanning && pendingAnalysisCount > 0)
        '$pendingAnalysisCount 個項目仍待分析；雲端原始素材不會自動下載，可在素材存於本機後繼續掃描。',
      if (!_nativeAvailable) '此裝置尚未提供本機原始素材分析，未確認容量與重複內容。',
    ];
    return notices.isEmpty ? null : notices.join('\n');
  }

  Future<void> startFullScan() => _scan(resume: false);
  Future<void> resumeScan() => _scan(resume: true);

  void cancelScan() {
    if (!_isScanning || _disposed) return;
    final prefix = '$_instanceId:$_scanRunId:';
    _scanRunId++;
    _cancellation?.complete();
    _cancellation = null;
    _isScanning = false;
    _wasCancelled = true;
    _hasCompletedScan = false;
    _currentPhase = ScanPhase.idle;
    _publish(groups: true);
    _cancelNative(prefix);
  }

  Future<void> _scan({required bool resume}) async {
    if (_disposed || _isScanning || _isDeleting) return;
    final runId = ++_scanRunId;
    _cancellation = Completer<void>();
    _isScanning = true;
    _wasCancelled = false;
    _hasCompletedScan = false;
    _lastError = null;
    _currentPhase = ScanPhase.fetchingAssets;
    final priorAssets = resume
        ? Map<String, PhotoAsset>.from(_assets)
        : <String, PhotoAsset>{};
    final priorEntities = resume
        ? Map<String, AssetEntity>.from(_entities)
        : <String, AssetEntity>{};
    final priorSignatures = resume
        ? Map<String, ContentSignature>.from(_signatures)
        : <String, ContentSignature>{};
    // Re-index on resume: the accessible set and edits may change without the
    // permission enum or total count changing. Never display revoked assets.
    _assets.clear();
    _entities.clear();
    _signatures.clear();
    _album = null;
    _nextAssetOffset = 0;
    _availableAssetCount = null;
    _scanResult = ScanResult.empty;
    _scanProgress = 0;
    notifyListeners();
    AnalyticsManager.instance.track(AnalyticsEvent.scanStarted.name);
    try {
      // Permission dialogs are user decisions and have no arbitrary deadline.
      final permission = await _awaitRun(
        PhotoManager.requestPermissionExtend(),
        runId,
      );
      _checkRun(runId);
      _hasLimitedAccess = permission.isLimited;
      if (!permission.hasAccess) {
        _assets.clear();
        _entities.clear();
        _signatures.clear();
        _availableAssetCount = null;
        _album = null;
        _nextAssetOffset = 0;
        _lastError = '尚未取得相簿權限，請在設定中允許存取照片後重試。';
        _finish(runId, completed: false);
        return;
      }
      if (_album == null) {
        final albums = await _awaitRun(
          PhotoManager.getAssetPathList(
            type: RequestType.common,
            filterOption: FilterOptionGroup(
              imageOption: const FilterOption(needTitle: false),
              videoOption: const FilterOption(needTitle: false),
            ),
          ),
          runId,
          timeout: _pageTimeout,
        );
        _checkRun(runId);
        if (albums.isEmpty) {
          _availableAssetCount = 0;
          _finish(runId);
          return;
        }
        _album = albums.firstWhere(
          (album) => album.isAll,
          orElse: () => albums.first,
        );
      }
      final count = await _awaitRun(
        _album!.assetCountAsync,
        runId,
        timeout: _pageTimeout,
      );
      _checkRun(runId);
      _availableAssetCount = count;
      while (_nextAssetOffset < count) {
        final end = math.min(_nextAssetOffset + _assetPageSize, count);
        final page = await _awaitRun(
          _album!.getAssetListRange(start: _nextAssetOffset, end: end),
          runId,
          timeout: _pageTimeout,
        );
        _checkRun(runId);
        if (page.isEmpty) {
          throw StateError('The album changed or a page could not be read.');
        }
        for (final entity in page) {
          _entities[entity.id] = entity;
          final previous = priorEntities[entity.id];
          if (previous != null &&
              previous.modifiedDateTime == entity.modifiedDateTime &&
              previous.width == entity.width &&
              previous.height == entity.height &&
              previous.type == entity.type) {
            final cached = priorAssets[entity.id];
            if (cached != null) _assets[entity.id] = cached;
            final signature = priorSignatures[entity.id];
            if (signature != null) _signatures[entity.id] = signature;
          }
          _assets.putIfAbsent(
            entity.id,
            () => PhotoAsset(
              id: entity.id,
              title: entity.title,
              width: entity.width,
              height: entity.height,
              size: 0,
              createDate: entity.createDateTime,
              type: entity.type,
              isScreenshot: _isScreenshot(entity),
            ),
          );
        }
        _nextAssetOffset = end;
        _scanProgress = count == 0 ? 0.45 : 0.45 * end / count;
        _publish();
        await Future<void>.delayed(Duration.zero);
        _checkRun(runId);
      }
      _currentPhase = ScanPhase.computingHashes;
      final pending = _assets.values
          .where((asset) => asset.analysisPending)
          .map((asset) => asset.id)
          .toList();
      var attempted = 0;
      for (var offset = 0; offset < pending.length; offset += 8) {
        final batch = pending.skip(offset).take(8).toList();
        final updates = <String, PhotoAsset>{};
        final thumbnailBytes = <String, Uint8List>{};
        for (final id in batch) {
          _checkRun(runId);
          final asset = _assets[id];
          if (asset == null) continue;
          final token = '$_instanceId:$runId:$id';
          Map<dynamic, dynamic>? data;
          if (_nativeAvailable) {
            try {
              data = await _awaitRun(
                _resourceChannel
                    .invokeMapMethod<String, dynamic>('inspectAsset', {
                      'assetId': id,
                      'token': token,
                      'includeHash': asset.type == AssetType.image,
                      'includeThumbnail': asset.type == AssetType.image,
                    }),
                runId,
                timeout: _analysisTimeout,
              );
            } on MissingPluginException {
              _nativeAvailable = false;
            } on TimeoutException {
              _cancelNative(token, exact: true);
            } on PlatformException {
              // Local Photos resources may be unavailable; keep them pending.
            }
          }
          _checkRun(runId);
          final complete = data?['complete'] == true;
          final nativeSize = data?['size'];
          final known =
              complete &&
              data?['sizeKnown'] == true &&
              nativeSize is num &&
              nativeSize > 0;
          final nativeHash = data?['hash'];
          final hash =
              known &&
                  complete &&
                  nativeHash is String &&
                  RegExp(r'^[a-f0-9]{64}$').hasMatch(nativeHash)
              ? nativeHash
              : null;
          final thumb = data?['thumbnail'];
          if (thumb is Uint8List && asset.type == AssetType.image) {
            thumbnailBytes[id] = thumb;
          }
          updates[id] = asset.copyWith(
            size: known ? nativeSize.toInt() : 0,
            sizeKnown: known,
            hash: hash,
            clearHash: hash == null,
            analysisPending:
                !known || (asset.type == AssetType.image && hash == null),
            pendingReason: data?['pendingReason'] as String?,
          );
          // Preserve successful resource reads even if cancellation happens
          // before the thumbnail batch finishes. Photo quality remains pending.
          _assets[id] = updates[id]!.copyWith(
            analysisPending: asset.type == AssetType.image || !known,
          );
          attempted++;
          _scanProgress = 0.45 + 0.50 * attempted / math.max(1, pending.length);
          notifyListeners();
        }
        if (thumbnailBytes.isNotEmpty) {
          final signatures = await _awaitRun(
            compute(_analyzeThumbnailBatch, thumbnailBytes),
            runId,
            timeout: _pageTimeout,
          );
          _checkRun(runId);
          for (final entry in signatures.entries) {
            _signatures[entry.key] = ContentSignature.fromMap(entry.value);
          }
        }
        _checkRun(runId);
        for (final entry in updates.entries) {
          final signature = _signatures[entry.key];
          final photo = entry.value;
          _assets[entry.key] = photo.copyWith(
            analysisPending:
                photo.analysisPending ||
                (photo.type == AssetType.image && signature?.isValid != true),
            qualityScore:
                signature?.isValid == true && !signature!.isLowInformation
                ? signature.qualityScore
                : null,
            qualityReasons: signature?.qualityReasons ?? const [],
            isBlurry:
                signature?.isValid == true &&
                !signature!.isLowInformation &&
                signature.sharpness < 0.004,
            isDark:
                signature?.isValid == true &&
                !signature!.isLowInformation &&
                signature.brightness < 0.15,
            isOverexposed:
                signature?.isValid == true &&
                !signature!.isLowInformation &&
                signature.brightness > 0.85,
          );
        }
        _publish();
        await Future<void>.delayed(Duration.zero);
        _checkRun(runId);
      }
      _finish(runId);
    } on _ScanCancelled {
      // cancelScan has already published a stable partial snapshot.
    } catch (error) {
      if (!_active(runId)) return;
      _lastError = error is TimeoutException
          ? '部分讀取逾時，已保留目前結果，可繼續掃描。'
          : '部分相簿讀取中斷，已保留目前結果，可繼續掃描。';
      _finish(runId, completed: false);
    }
  }

  Future<T> _awaitRun<T>(Future<T> future, int runId, {Duration? timeout}) {
    _checkRun(runId);
    final result = Completer<T>();
    Timer? timer;
    void fail(Object error, [StackTrace? stack]) {
      if (result.isCompleted) return;
      timer?.cancel();
      result.completeError(error, stack);
    }

    if (timeout != null) {
      timer = Timer(
        timeout,
        () => fail(TimeoutException('Photo operation timed out', timeout)),
      );
    }
    future.then((value) {
      if (result.isCompleted) return;
      timer?.cancel();
      result.complete(value);
    }, onError: (Object error, StackTrace stack) => fail(error, stack));
    _cancellation!.future.then((_) => fail(_ScanCancelled()));
    return result.future;
  }

  bool _active(int runId) => !_disposed && _isScanning && _scanRunId == runId;
  void _checkRun(int runId) {
    if (!_active(runId)) throw _ScanCancelled();
  }

  void _cancelNative(String token, {bool exact = false}) {
    unawaited(
      _resourceChannel
          .invokeMethod<void>('cancelInspections', {
            exact ? 'token' : 'prefix': token,
          })
          .catchError((Object _) {}),
    );
  }

  void _finish(int runId, {bool completed = true}) {
    if (!_active(runId)) return;
    _hasCompletedScan = completed;
    _isScanning = false;
    _cancellation?.complete();
    _cancellation = null;
    _currentPhase = ScanPhase.done;
    if (completed) _scanProgress = 1;
    _publish(groups: true);
    AnalyticsManager.instance.track(
      AnalyticsEvent.scanCompleted.name,
      properties: {
        'assets': scannedAssetCount,
        'analyzed_assets': analyzedAssetCount,
        'pending_analysis': pendingAnalysisCount,
        'complete': completed,
        'duplicates': _scanResult.duplicateGroups.length,
        'similar_groups': _scanResult.similarGroups.length,
      },
    );
  }

  bool _isScreenshot(AssetEntity asset) {
    final title = (asset.title ?? '').toLowerCase();
    return asset.type == AssetType.image &&
        ((asset.subtype & (1 << 2)) != 0 ||
            title.contains('screenshot') ||
            title.contains('screen shot') ||
            title.contains('截圖') ||
            title.contains('螢幕快照'));
  }

  String _bestReason(PhotoAsset asset, {required bool exact}) {
    if (asset.qualityReasons.isNotEmpty && asset.qualityScore != null) {
      return '${asset.qualityReasons.join('、')}；僅供保留參考';
    }
    return exact ? '已確認原始及編輯素材內容完全相同，建議保留這一份' : '此群組中解析度較高，建議先保留；仍需確認照片內容';
  }

  List<PhotoAsset> _recommended(List<PhotoAsset> assets) =>
      List<PhotoAsset>.from(assets)..sort((a, b) {
        final quality = (b.qualityScore ?? -1).compareTo(a.qualityScore ?? -1);
        if (quality != 0) return quality;
        final resolution = (b.width * b.height).compareTo(a.width * a.height);
        return resolution != 0 ? resolution : a.id.compareTo(b.id);
      });

  void _publish({bool groups = false}) {
    if (_disposed) return;
    final assets = _assets.values.toList()
      ..sort((a, b) => b.createDate.compareTo(a.createDate));
    var duplicateGroups = _scanResult.duplicateGroups;
    var similarGroups = _scanResult.similarGroups;
    if (groups) {
      final buckets = <String, List<PhotoAsset>>{};
      for (final asset in assets) {
        if (asset.type == AssetType.image &&
            asset.sizeKnown &&
            asset.hash != null) {
          buckets.putIfAbsent(asset.hash!, () => []).add(asset);
        }
      }
      duplicateGroups = buckets.entries
          .where((entry) => entry.value.length > 1)
          .map((entry) {
            final ordered = _recommended(entry.value);
            return DuplicateGroup(
              hash: entry.key,
              assets: ordered,
              bestAssetId: ordered.first.id,
              bestReason: _bestReason(ordered.first, exact: true),
            );
          })
          .toList();
      final exactIds = duplicateGroups
          .expand((group) => group.assets)
          .map((asset) => asset.id)
          .toSet();
      final candidates = assets
          .where(
            (asset) =>
                asset.type == AssetType.image &&
                !asset.analysisPending &&
                !exactIds.contains(asset.id),
          )
          .map(
            (asset) => AnalyzedPhoto(
              id: asset.id,
              width: asset.width,
              height: asset.height,
              createDate: asset.createDate,
              signature: _signatures[asset.id],
            ),
          )
          .toList();
      similarGroups = groupSimilarPhotos(candidates).map((ids) {
        final ordered = _recommended(ids.map((id) => _assets[id]!).toList());
        final distance = visualDistance(
          _signatures[ordered[0].id]!,
          _signatures[ordered[1].id]!,
        );
        return SimilarGroup(
          assets: ordered,
          hammingDistance: distance ?? 0,
          bestAssetId: ordered.first.id,
          bestReason: _bestReason(ordered.first, exact: false),
        );
      }).toList();
    }
    _scanResult = ScanResult(
      allAssets: assets,
      duplicateGroups: duplicateGroups,
      similarGroups: similarGroups,
      screenshots: assets.where((asset) => asset.isScreenshot).toList(),
      largeFiles:
          assets
              .where((asset) => asset.sizeKnown && asset.size > 5 * 1024 * 1024)
              .toList()
            ..sort((a, b) => b.size.compareTo(a.size)),
      videos: assets.where((asset) => asset.type == AssetType.video).toList()
        ..sort((a, b) => b.size.compareTo(a.size)),
      blurryPhotos: assets.where((asset) => asset.isBlurry).toList(),
      darkPhotos: assets.where((asset) => asset.isDark).toList(),
      overexposedPhotos: assets.where((asset) => asset.isOverexposed).toList(),
      totalSavingsEstimate: 0,
    );
    notifyListeners();
  }

  Future<bool> deleteAssets(List<PhotoAsset> assets) async =>
      (await deleteAssetsWithResult(assets)).isNotEmpty;
  Future<Set<String>> deleteAssetsWithResult(List<PhotoAsset> assets) async {
    final ids = assets.map((asset) => asset.id).toSet();
    if (_disposed || _isScanning || _isDeleting || ids.isEmpty) return {};
    _isDeleting = true;
    notifyListeners();
    try {
      final result = await PhotoManager.editor.deleteWithIds(ids.toList());
      final deleted = result.toSet().intersection(ids);
      if (_disposed) return deleted;
      final indexedDeleted = deleted.where(_assets.containsKey).length;
      for (final id in deleted) {
        _assets.remove(id);
        _entities.remove(id);
        _signatures.remove(id);
      }
      _nextAssetOffset = math.max(0, _nextAssetOffset - indexedDeleted);
      if (_availableAssetCount != null) {
        _availableAssetCount = math.max(
          0,
          _availableAssetCount! - deleted.length,
        );
      }
      if (deleted.isNotEmpty) {
        _publish(groups: true);
        AnalyticsManager.instance.track(
          AnalyticsEvent.photosDeleted.name,
          properties: {'count': deleted.length},
        );
      }
      return deleted;
    } catch (error) {
      debugPrint('PhotoScannerService.deleteAssets error: $error');
      return {};
    } finally {
      _isDeleting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    final prefix = '$_instanceId:$_scanRunId:';
    _disposed = true;
    _isScanning = false;
    _scanRunId++;
    _cancellation?.complete();
    _cancellation = null;
    _cancelNative(prefix);
    super.dispose();
  }
}
