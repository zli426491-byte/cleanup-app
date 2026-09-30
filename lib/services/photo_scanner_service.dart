import 'dart:async';
import 'dart:math' as math;
import 'dart:isolate';

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

enum OriginalVerificationTarget { all, exactPhotos, fileSizes }

class PhotoAsset {
  final String id;
  final String? title;
  final int width;
  final int height;
  final int size; // bytes
  final bool sizeKnown;
  final bool analysisPending;
  final bool analysisAttempted;
  final bool resourceAnalysisPending;
  final bool resourceAnalysisAttempted;
  final bool previewDegraded;
  final double? qualityScore;
  final List<String> qualityReasons;
  final String? pendingReason;
  final String? resourcePendingReason;
  final DateTime createDate;
  final DateTime? modifiedDate;
  final int durationSeconds;
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
    this.analysisAttempted = false,
    this.resourceAnalysisPending = true,
    this.resourceAnalysisAttempted = false,
    this.previewDegraded = false,
    this.qualityScore,
    this.qualityReasons = const [],
    this.pendingReason,
    this.resourcePendingReason,
    required this.createDate,
    this.modifiedDate,
    this.durationSeconds = 0,
    required this.type,
    this.thumbnail,
    this.hash,
    this.isScreenshot = false,
    this.isBlurry = false,
    this.isDark = false,
    this.isOverexposed = false,
  });

  PhotoAsset copyWith({
    DateTime? modifiedDate,
    int? durationSeconds,
    bool clearHash = false,
    bool clearResourcePendingReason = false,
    int? size,
    bool? sizeKnown,
    bool? analysisPending,
    bool? analysisAttempted,
    bool? resourceAnalysisPending,
    bool? resourceAnalysisAttempted,
    bool? previewDegraded,
    double? qualityScore,
    List<String>? qualityReasons,
    String? pendingReason,
    String? resourcePendingReason,
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
      analysisAttempted: analysisAttempted ?? this.analysisAttempted,
      resourceAnalysisPending:
          resourceAnalysisPending ?? this.resourceAnalysisPending,
      resourceAnalysisAttempted:
          resourceAnalysisAttempted ?? this.resourceAnalysisAttempted,
      previewDegraded: previewDegraded ?? this.previewDegraded,
      qualityScore: qualityScore ?? this.qualityScore,
      qualityReasons: qualityReasons ?? this.qualityReasons,
      pendingReason: pendingReason ?? this.pendingReason,
      resourcePendingReason: clearResourcePendingReason
          ? null
          : resourcePendingReason ?? this.resourcePendingReason,
      createDate: createDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      durationSeconds: durationSeconds ?? this.durationSeconds,
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

void _analysisWorker(List<Object> request) {
  final reply = request[0] as SendPort;
  try {
    reply.send([
      true,
      Function.apply(request[1] as Function, [request[2]]),
    ]);
  } catch (error) {
    reply.send([false, error.toString()]);
  }
}

class _ScanCancelled implements Exception {}

class _RoundBudgetExpired implements Exception {}

class PhotoScannerService extends ChangeNotifier {
  static const _assetPageSize = 120;
  static const _scopeCheckPageSize = 960;
  // Keep the first preview small so the home screen becomes useful quickly,
  // then amortize PhotoKit/Flutter channel overhead across a larger batch.
  // Native preview requests are concurrent and bounded independently.
  static const _firstPreviewBatchSize = 8;
  static const _previewBatchSize = 32;
  static const _pageTimeout = Duration(seconds: 30);
  static const _previewTimeout = Duration(milliseconds: 2500);
  static const _widePreviewTimeout = Duration(milliseconds: 6500);
  static const _previewRoundBudget = Duration(seconds: 30);
  static const _defaultContinuousPreviewRoundBudget = Duration(minutes: 2);
  static const _defaultContinuousScanBudget = Duration(minutes: 10);
  static const _resourceRoundBudget = Duration(seconds: 60);
  static const _resourceTimeout = Duration(seconds: 5);
  static const _resourceChannel = MethodChannel('cleanup/photo_resources');
  static int _instances = 0;
  final String _instanceId = 'scanner-${++_instances}';
  final Duration _continuousPreviewRoundBudget;
  final Duration _continuousScanBudget;
  bool _continuousScanActive = false;
  bool _continuousStopRequested = false;
  bool _resumeContinuousAfterAccessRefresh = false;
  Completer<void>? _continuousStopped;
  bool _isScanning = false;
  bool _isDeleting = false;
  bool _isVerifyingOriginals = false;
  int _analyzedCount = 0;
  int _pendingCount = 0;
  int _attemptedCount = 0;
  int _cloudCount = 0;
  int _verifiedCount = 0;
  int _pendingResourceCount = 0;
  int _attemptedResourceCount = 0;
  int _knownSizeCount = 0;
  int _verifiedHashCount = 0;
  String? _currentOperation;
  int _currentWaitSeconds = 0;
  Timer? _heartbeat;
  Timer? _budgetTimer;
  bool _budgetReached = false;
  void Function(Object)? _abortWait;
  final Stopwatch _snapshotClock = Stopwatch();
  bool _disposed = false;
  bool _wasCancelled = false;
  bool _nativeAvailable;
  bool _hasCompletedScan = false;
  bool _hasLimitedAccess = false;
  PermissionState? _photoPermission;
  bool _photoAccessRefreshPending = false;
  bool _checkingPhotoAccess = false;
  bool _photoScopeChanged = false;
  OriginalVerificationTarget? _originalVerificationTarget;
  int? _originalRoundTotal;
  int _originalRoundProcessed = 0;
  int _knownLibraryBytes = 0;
  int _scanRunId = 0;
  int _nextAssetOffset = 0;
  int? _availableAssetCount;
  double _scanProgress = 0;
  String? _lastError;
  ScanPhase _currentPhase = ScanPhase.idle;
  ScanResult _scanResult = ScanResult.empty;
  AssetPathEntity? _album;

  final Map<String, AssetEntity> _entities = {};
  final Map<String, PhotoAsset> _assets = {};
  final Map<String, ContentSignature> _signatures = {};
  // Checkpoints survive an interrupted re-index, but are never displayed until
  // the current permission scope and modification dates have been revalidated.
  final Map<String, AssetEntity> _checkpointEntities = {};
  final Map<String, PhotoAsset> _checkpointAssets = {};
  final Map<String, ContentSignature> _checkpointSignatures = {};
  // Hash and capacity attempts are independent: a size-only pass must not make
  // an untried photo hash look attempted. Sequence numbers rotate failed work
  // across bounded rounds, including an item cancelled while native is waiting.
  final Map<String, int> _hashAttempts = {};
  final Map<String, int> _sizeAttempts = {};
  int _resourceAttemptSequence = 0;
  List<String>? _orderedIds;
  List<DuplicateGroup> _duplicateGroups = [];
  List<SimilarGroup> _similarGroups = [];

  PhotoScannerService({
    bool? supportsNativeResources,
    Duration continuousPreviewRoundBudget =
        _defaultContinuousPreviewRoundBudget,
    Duration continuousScanBudget = _defaultContinuousScanBudget,
  }) : assert(continuousPreviewRoundBudget > Duration.zero),
       assert(continuousScanBudget > Duration.zero),
       _continuousPreviewRoundBudget = continuousPreviewRoundBudget,
       _continuousScanBudget = continuousScanBudget,
       _nativeAvailable =
           supportsNativeResources ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  // Keep the UI busy across the brief handoff between automatic rounds.
  bool get isScanning => _isScanning || _continuousScanActive;
  bool get isContinuousScanning => _continuousScanActive;
  bool get isDeleting => _isDeleting;
  bool get wasCancelled => _wasCancelled;
  bool get hasCompletedScan => _hasCompletedScan;
  double get scanProgress => _scanProgress;
  ScanPhase get currentPhase => _currentPhase;
  ScanResult get scanResult => _scanResult;
  String? get lastError => _lastError;
  int? get availableAssetCount => _availableAssetCount;
  int get scannedAssetCount => _assets.length;
  int get analyzedAssetCount => _analyzedCount;
  int get pendingAnalysisCount => _pendingCount;
  int get attemptedAnalysisCount => _attemptedCount;
  int get cloudPendingCount => _cloudCount;
  int get verifiedOriginalCount => _verifiedCount;
  int get pendingResourceCount => _pendingResourceCount;
  int get attemptedResourceCount => _attemptedResourceCount;
  int get knownSizeAssetCount => _knownSizeCount;
  int get knownLibraryBytes => _knownLibraryBytes;
  bool get hasLimitedAccess => _hasLimitedAccess;
  bool get permissionDenied =>
      _photoPermission != null && !_photoPermission!.hasAccess;
  bool get photoScopeChanged => _photoScopeChanged;
  OriginalVerificationTarget? get originalVerificationTarget =>
      _originalVerificationTarget;
  int? get originalRoundTotal => _originalRoundTotal;
  int get originalRoundProcessed => _originalRoundProcessed;
  int get pendingSizeAssetCount => scannedAssetCount - _knownSizeCount;
  int get verifiedHashAssetCount => _verifiedHashCount;
  int get pendingHashAssetCount => totalPhotoCount - _verifiedHashCount;
  int get totalPhotoCount => _analyzedCount + _pendingCount;
  bool get isVerifyingOriginals => _isVerifyingOriginals;
  bool get nativeOriginalAnalysisAvailable => _nativeAvailable;
  String? get currentOperation => _currentOperation;
  int get currentWaitSeconds => _currentWaitSeconds;
  String? get scanNotice {
    final notices = <String>[
      ?_lastError,
      if (_wasCancelled) '已暫停，已讀取與分析的結果已保留，可繼續掃描。',
      if (_availableAssetCount != null &&
          scannedAssetCount < _availableAssetCount!)
        '已讀取 $scannedAssetCount / $_availableAssetCount 個可存取項目。',
      if (_hasLimitedAccess) '僅整理你允許存取的照片，未讀取整個相簿。',
      if (!isScanning && pendingAnalysisCount > 0)
        '$pendingAnalysisCount 張照片仍待視覺分析；繼續掃描會先處理尚未嘗試的照片，不自動下載雲端素材。',
      if (!_nativeAvailable) '此裝置尚未提供本機原始素材分析，未確認容量與重複內容。',
      if (!isScanning && _nativeAvailable && pendingResourceCount > 0)
        '素材容量與完全重複另需驗證本機原始素材；大型或雲端素材可能仍待驗證，未驗證項目不估算容量。',
    ];
    return notices.isEmpty ? null : notices.join('\n');
  }

  Future<void> startFullScan() =>
      _continuousScanActive ? Future<void>.value() : _scan(resume: false);
  Future<void> resumeScan() =>
      _continuousScanActive ? Future<void>.value() : _scan(resume: true);

  /// Continue foreground preview analysis through bounded rounds without
  /// asking the user to tap Resume after every deadline. Every image is tried
  /// at most once during this call, including cloud-only and timed-out items.
  /// A later explicit retry remains possible. Cancel retains the safe snapshot.
  Future<void> startContinuousScan({bool resume = false}) async {
    if (_disposed || _isScanning || _isDeleting || _continuousScanActive) {
      return;
    }
    _continuousScanActive = true;
    _continuousStopRequested = false;
    _continuousStopped = Completer<void>();
    final retryIds = <String>{
      if (resume)
        for (final asset in _checkpointAssets.values)
          if (asset.type == AssetType.image &&
              asset.analysisPending &&
              asset.analysisAttempted)
            asset.id,
    };
    final clock = Stopwatch()..start();
    var useCheckpoint = resume;
    var previousAttempted = -1;
    var previousIndexed = -1;
    var reusedIndex = false;
    try {
      while (!_disposed && !_continuousStopRequested) {
        final reuse = useCheckpoint && await _canReusePreviewIndex();
        if (_continuousStopRequested || _disposed) break;
        if (reuse) {
          reusedIndex = true;
          await _scanPreviewRoundInPlace(retryIds);
        } else {
          await _scan(
            resume: useCheckpoint,
            retryEligiblePreviewIds: retryIds,
            previewRoundBudget: _continuousPreviewRoundBudget,
          );
        }
        useCheckpoint = true;
        if (_disposed ||
            _continuousStopRequested ||
            _wasCancelled ||
            permissionDenied ||
            !_nativeAvailable) {
          break;
        }
        final indexed = _nextAssetOffset;
        final attempted = _attemptedCount;
        final indexedAll =
            _availableAssetCount != null &&
            _nextAssetOffset == _availableAssetCount &&
            _assets.length == _availableAssetCount;
        if (_hasCompletedScan || (indexedAll && attempted >= totalPhotoCount)) {
          break;
        }
        if (indexed <= previousIndexed && attempted <= previousAttempted) {
          // A permanently failing page or native callback cannot spin forever.
          break;
        }
        previousIndexed = indexed;
        previousAttempted = attempted;
        if (clock.elapsed >= _continuousScanBudget) {
          _lastError = '本次連續掃描已達時間上限；已保留進度，稍後可繼續。';
          notifyListeners();
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }
      if (reusedIndex && !_disposed && !_continuousStopRequested) {
        final matches = await _continuousSnapshotMatchesLibrary();
        if (!_disposed && !_continuousStopRequested && !matches) {
          // PhotoKit can change while a long scan is running. Revalidate once
          // at the end; only a changed scope needs the expensive full re-index.
          await _scan(
            resume: true,
            retryEligiblePreviewIds: retryIds,
            previewRoundBudget: _continuousPreviewRoundBudget,
          );
        }
      }
    } finally {
      _continuousScanActive = false;
      _continuousStopRequested = false;
      clock.stop();
      _continuousStopped?.complete();
      _continuousStopped = null;
      if (!_disposed) notifyListeners();
      _drainPhotoAccessRefresh();
    }
  }

  /// Pause an automatic preview scan and wait until targeted original-resource
  /// verification is allowed to start. The indexed results remain available.
  Future<void> pauseContinuousScan() async {
    if (!_continuousScanActive) return;
    final stopped = _continuousStopped!.future;
    cancelScan();
    await stopped;
  }

  Future<bool> _canReusePreviewIndex() async {
    if (_disposed ||
        _continuousStopRequested ||
        _photoAccessRefreshPending ||
        _album == null ||
        _availableAssetCount == null ||
        _nextAssetOffset != _availableAssetCount ||
        _photoPermission?.hasAccess != true ||
        _assets.length != _availableAssetCount) {
      return false;
    }
    try {
      final state = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      ).timeout(const Duration(seconds: 5));
      if (_continuousStopRequested || state != _photoPermission) return false;
      final count = await _album!.assetCountAsync.timeout(
        const Duration(seconds: 5),
      );
      return !_continuousStopRequested &&
          count == _availableAssetCount &&
          await _previewIndexMatchesLibrary();
    } catch (_) {
      return false;
    }
  }

  /// An unchanged count alone does not validate a Photos scope: an edit or a
  /// remove/add pair can preserve it. Check every accessible ID and version
  /// before retaining visible groups and original-resource results in place.
  Future<bool> _previewIndexMatchesLibrary() async {
    final album = _album;
    final count = _availableAssetCount;
    if (album == null || count == null || _assets.length != count) return false;
    final remaining = _assets.keys.toSet();
    final refreshedMetadata = <String, AssetEntity>{};
    try {
      for (var start = 0; start < count; start += _scopeCheckPageSize) {
        if (_disposed ||
            _continuousStopRequested ||
            _photoAccessRefreshPending) {
          return false;
        }
        final end = math.min(start + _scopeCheckPageSize, count);
        final page = await album
            .getAssetListRange(start: start, end: end)
            .timeout(const Duration(seconds: 5));
        if (page.length != end - start) return false;
        for (final entity in page) {
          final cached = _assets[entity.id];
          if (cached == null ||
              !remaining.remove(entity.id) ||
              !_sameContentVersion(cached, entity)) {
            return false;
          }
          if (!_sameDisplayMetadata(cached, entity)) {
            refreshedMetadata[entity.id] = entity;
          }
        }
      }
      if (remaining.isNotEmpty ||
          _disposed ||
          _continuousStopRequested ||
          _photoAccessRefreshPending) {
        return false;
      }
      final finalCount = await album.assetCountAsync.timeout(
        const Duration(seconds: 5),
      );
      if (_disposed ||
          _continuousStopRequested ||
          _photoAccessRefreshPending ||
          finalCount != count) {
        return false;
      }
      for (final entry in refreshedMetadata.entries) {
        final cached = _assets[entry.key]!;
        _entities[entry.key] = entry.value;
        _checkpointEntities[entry.key] = entry.value;
        _setAsset(_withCurrentMetadata(cached, entry.value));
      }
      if (refreshedMetadata.isNotEmpty) {
        final ordered = _assets.values.toList()
          ..sort((a, b) => b.createDate.compareTo(a.createDate));
        _orderedIds = ordered.map((asset) => asset.id).toList();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // PhotoKit's modified time, dimensions and media type version the original
  // content. Title, creation date, duration and screenshot presentation can
  // vary between fetches without changing the bytes behind a verified SHA.
  bool _sameContentVersion(PhotoAsset cached, AssetEntity entity) =>
      cached.modifiedDate == entity.modifiedDateTime &&
      cached.width == entity.width &&
      cached.height == entity.height &&
      cached.type == entity.type;

  bool _sameDisplayMetadata(PhotoAsset cached, AssetEntity entity) =>
      cached.createDate == entity.createDateTime &&
      cached.durationSeconds == entity.duration &&
      cached.isScreenshot == _isScreenshot(entity) &&
      cached.title == entity.title;

  PhotoAsset _withCurrentMetadata(PhotoAsset cached, AssetEntity entity) =>
      PhotoAsset(
        id: cached.id,
        title: entity.title,
        width: entity.width,
        height: entity.height,
        size: cached.size,
        sizeKnown: cached.sizeKnown,
        analysisPending: cached.analysisPending,
        analysisAttempted: cached.analysisAttempted,
        resourceAnalysisPending: cached.resourceAnalysisPending,
        resourceAnalysisAttempted: cached.resourceAnalysisAttempted,
        previewDegraded: cached.previewDegraded,
        qualityScore: cached.qualityScore,
        qualityReasons: cached.qualityReasons,
        pendingReason: cached.pendingReason,
        resourcePendingReason: cached.resourcePendingReason,
        createDate: entity.createDateTime,
        modifiedDate: entity.modifiedDateTime,
        durationSeconds: entity.duration,
        type: entity.type,
        thumbnail: cached.thumbnail,
        hash: cached.hash,
        isScreenshot: _isScreenshot(entity),
        isBlurry: cached.isBlurry,
        isDark: cached.isDark,
        isOverexposed: cached.isOverexposed,
      );

  Future<bool> _continuousSnapshotMatchesLibrary() async {
    if (_disposed || _continuousStopRequested || _photoAccessRefreshPending) {
      return false;
    }
    try {
      final state = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      ).timeout(const Duration(seconds: 5));
      if (state != _photoPermission || !state.hasAccess) return false;
      return await _limitedPhotoScopeMatches(
        () => !_disposed && !_continuousStopRequested,
      ).timeout(const Duration(seconds: 30));
    } catch (_) {
      return false;
    }
  }

  Future<void> _scanPreviewRoundInPlace(Set<String> retryIds) async {
    if (_disposed || _isScanning || _isDeleting || _continuousStopRequested) {
      return;
    }
    final runId = ++_scanRunId;
    _isScanning = true;
    _isVerifyingOriginals = false;
    _originalVerificationTarget = null;
    _originalRoundTotal = null;
    _originalRoundProcessed = 0;
    _wasCancelled = false;
    _hasCompletedScan = false;
    _lastError = null;
    _currentPhase = ScanPhase.computingHashes;
    _setOperation('分析本機預覽（$pendingAnalysisCount 張）');
    notifyListeners();
    try {
      await _analyzeLocalPreviews(
        runId,
        retryEligibleIds: retryIds,
        roundBudget: _continuousPreviewRoundBudget,
      );
      await _finish(runId, completed: _previewRoundComplete(retryIds));
    } on _RoundBudgetExpired {
      if (!_active(runId)) return;
      _cancelNative('$_instanceId:$runId:');
      _lastError = '部分讀取逾時，已保留目前結果，可繼續掃描。';
      await _finish(runId, completed: false, refresh: false);
    } on _ScanCancelled {
      // cancelScan already published the stable partial snapshot.
    } catch (_) {
      if (!_active(runId)) return;
      _lastError = '部分相簿讀取中斷，已保留目前結果，可繼續掃描。';
      await _finish(runId, completed: false, refresh: false);
    }
  }

  Future<bool> openPhotoSettings() async {
    try {
      await PhotoManager.openSetting();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshPhotoAccess() async {
    if (_disposed) return;
    _photoAccessRefreshPending = true;
    if (_continuousScanActive) {
      // A foreground return can also mean Photos access changed in Settings.
      // Stop the long-running scan now so a revoked snapshot is not kept on
      // screen until its next (potentially ten-minute) completion.
      // An explicit user cancellation already in flight must stay cancelled.
      if (!_continuousStopRequested) {
        _resumeContinuousAfterAccessRefresh = true;
      }
      cancelScan();
      return;
    }
    if (isScanning || _isDeleting || _checkingPhotoAccess) return;
    _photoAccessRefreshPending = false;
    _checkingPhotoAccess = true;
    final runId = _scanRunId;
    final snapshot = _scanResult;
    final previous = _photoPermission;
    var mayResumeContinuous = false;
    var checkAlive = true;
    bool canApply() =>
        checkAlive &&
        !_disposed &&
        !isScanning &&
        !_isDeleting &&
        runId == _scanRunId &&
        identical(snapshot, _scanResult);
    try {
      final (state, unchanged) = await (() async {
        final state = await PhotoManager.getPermissionState(
          requestOption: const PermissionRequestOption(),
        );
        if (!canApply()) throw StateError('Photo scope check superseded');
        final unchanged =
            state == previous &&
            (!state.isLimited || await _limitedPhotoScopeMatches(canApply));
        return (state, unchanged);
      })().timeout(const Duration(seconds: 5));
      if (!canApply()) {
        if (!_disposed) _photoAccessRefreshPending = true;
        return;
      }
      if (unchanged) {
        mayResumeContinuous = state.hasAccess;
        return;
      }
      _photoScopeChanged = previous?.hasAccess == true;
      _photoPermission = state;
      _hasLimitedAccess = state.isLimited;
      if (previous?.hasAccess == true || !state.hasAccess) {
        _invalidatePhotoScope();
      }
      _lastError = state.hasAccess ? null : '尚未取得相簿權限，請在設定中允許存取照片後重試。';
      notifyListeners();
    } catch (_) {
      if (!canApply()) {
        if (!_disposed) _photoAccessRefreshPending = true;
      } else if (previous?.isLimited == true) {
        // An incomplete metadata check cannot authorize keeping a stale scope.
        _photoScopeChanged = true;
        _invalidatePhotoScope();
        _lastError = null;
        notifyListeners();
      }
    } finally {
      checkAlive = false;
      _checkingPhotoAccess = false;
      _drainPhotoAccessRefresh();
      final resumeContinuous =
          _resumeContinuousAfterAccessRefresh &&
          mayResumeContinuous &&
          !_photoAccessRefreshPending &&
          !_disposed;
      if (!_photoAccessRefreshPending) {
        _resumeContinuousAfterAccessRefresh = false;
      }
      if (resumeContinuous) {
        unawaited(startContinuousScan(resume: true));
      }
    }
  }

  Future<bool> _limitedPhotoScopeMatches(bool Function() canApply) async {
    final indexed = Map<String, PhotoAsset>.of(_assets);
    final expectedCount = _availableAssetCount;
    if (indexed.isEmpty && expectedCount == null) return true;
    if (expectedCount == null) return false;
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(needTitle: false),
        videoOption: const FilterOption(needTitle: false),
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    if (!canApply()) throw StateError('Photo scope check superseded');
    if (albums.isEmpty) return expectedCount == 0 && indexed.isEmpty;
    final album = albums.firstWhere((a) => a.isAll, orElse: () => albums.first);
    final count = await album.assetCountAsync;
    if (!canApply()) throw StateError('Photo scope check superseded');
    if (count != expectedCount) return false;
    final remaining = Set<String>.of(indexed.keys);
    final seen = <String>{};
    for (
      var start = 0;
      start < count && remaining.isNotEmpty;
      start += _assetPageSize
    ) {
      final end = math.min(start + _assetPageSize, count);
      final page = await album.getAssetListRange(start: start, end: end);
      if (!canApply()) throw StateError('Photo scope check superseded');
      if (page.length != end - start) return false;
      for (final entity in page) {
        if (!seen.add(entity.id)) return false;
        final current = indexed[entity.id];
        if (current == null) continue;
        // A changed presentation field also needs a fresh published snapshot.
        // A continuous scan will re-index once after this check fails.
        if (!_sameContentVersion(current, entity) ||
            !_sameDisplayMetadata(current, entity)) {
          return false;
        }
        remaining.remove(entity.id);
      }
    }
    if (remaining.isNotEmpty) return false;
    final finalCount = await album.assetCountAsync;
    if (!canApply()) throw StateError('Photo scope check superseded');
    return finalCount == expectedCount;
  }

  void _invalidatePhotoScope() {
    // Permission changes invalidate the visible scope. Never retain a full
    // library snapshot after the user narrows or revokes access in Settings.
    _assets.clear();
    _entities.clear();
    _signatures.clear();
    _checkpointAssets.clear();
    _checkpointEntities.clear();
    _checkpointSignatures.clear();
    _hashAttempts.clear();
    _sizeAttempts.clear();
    _duplicateGroups = [];
    _similarGroups = [];
    _orderedIds = null;
    _scanResult = ScanResult.empty;
    _availableAssetCount = null;
    _hasCompletedScan = false;
    _wasCancelled = false;
    _nextAssetOffset = 0;
    _album = null;
    _resetCounters();
  }

  void _drainPhotoAccessRefresh() {
    if (_photoAccessRefreshPending &&
        !_disposed &&
        !isScanning &&
        !_isDeleting &&
        !_checkingPhotoAccess) {
      unawaited(refreshPhotoAccess());
    }
  }

  Future<void> managePhotoAccess() async {
    if (_disposed || isScanning || _isDeleting) return;
    await PhotoManager.presentLimited(type: RequestType.common);
    if (!_disposed) await resumeScan();
  }

  /// An explicit, bounded local-resource pass; never runs as part of a preview scan.
  /// Re-index first so revoked access or same-ID edits cannot reuse old hashes.
  Future<void> verifyOriginals({
    OriginalVerificationTarget target = OriginalVerificationTarget.all,
  }) => _continuousScanActive
      ? Future<void>.value()
      : _scan(resume: true, originals: true, target: target);

  void cancelScan() {
    if (_disposed) return;
    _continuousStopRequested = true;
    if (!_isScanning) {
      if (_continuousScanActive) {
        _wasCancelled = true;
        notifyListeners();
      }
      return;
    }
    final prefix = '$_instanceId:$_scanRunId:';
    _scanRunId++;
    _abortWait?.call(_ScanCancelled());
    _abortWait = null;
    _isScanning = false;
    _stopRound();
    _wasCancelled = true;
    _hasCompletedScan = false;
    _currentPhase = ScanPhase.idle;
    _publish(groups: true);
    _cancelNative(prefix);
    _drainPhotoAccessRefresh();
  }

  Future<void> _scan({
    required bool resume,
    bool originals = false,
    OriginalVerificationTarget target = OriginalVerificationTarget.all,
    Set<String>? retryEligiblePreviewIds,
    Duration previewRoundBudget = _previewRoundBudget,
  }) async {
    if (_disposed || _isScanning || _isDeleting) return;
    final runId = ++_scanRunId;

    _isScanning = true;
    _isVerifyingOriginals = originals;
    _originalVerificationTarget = originals ? target : null;
    _originalRoundTotal = null;
    _originalRoundProcessed = 0;
    _setOperation('讀取相簿索引');
    _wasCancelled = false;
    _photoScopeChanged = false;
    _hasCompletedScan = false;
    _lastError = null;
    _currentPhase = ScanPhase.fetchingAssets;
    final priorAssets = resume
        ? Map<String, PhotoAsset>.from(_checkpointAssets)
        : <String, PhotoAsset>{};
    final priorEntities = resume
        ? Map<String, AssetEntity>.from(_checkpointEntities)
        : <String, AssetEntity>{};
    final priorSignatures = resume
        ? Map<String, ContentSignature>.from(_checkpointSignatures)
        : <String, ContentSignature>{};
    final originalCandidates = <String>{
      for (final group in _similarGroups)
        for (final asset in group.assets) asset.id,
    };
    if (!resume) {
      _checkpointAssets.clear();
      _checkpointEntities.clear();
      _checkpointSignatures.clear();
      _hashAttempts.clear();
      _sizeAttempts.clear();
      _resourceAttemptSequence = 0;
    }
    _orderedIds = null;
    // Re-index on resume: the accessible set and edits may change without the
    // permission enum or total count changing. Never display revoked assets.
    _assets.clear();
    _resetCounters();
    _entities.clear();
    _signatures.clear();
    _album = null;
    _nextAssetOffset = 0;
    _availableAssetCount = null;
    _scanResult = ScanResult.empty;
    _duplicateGroups = [];
    _similarGroups = [];
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
      _photoPermission = permission;
      _hasLimitedAccess = permission.isLimited;
      if (!permission.hasAccess) {
        _checkpointAssets.clear();
        _checkpointEntities.clear();
        _checkpointSignatures.clear();
        _hashAttempts.clear();
        _sizeAttempts.clear();
        _assets.clear();
        _entities.clear();
        _signatures.clear();
        _availableAssetCount = null;
        _album = null;
        _nextAssetOffset = 0;
        _lastError = '尚未取得相簿權限，請在設定中允許存取照片後重試。';
        await _finish(runId, completed: false, refresh: false);
        return;
      }
      if (_album == null) {
        final albums = await _awaitRun(
          PhotoManager.getAssetPathList(
            type: RequestType.common,
            filterOption: FilterOptionGroup(
              imageOption: const FilterOption(needTitle: false),
              videoOption: const FilterOption(needTitle: false),
              orders: const [
                OrderOption(type: OrderOptionType.createDate, asc: false),
              ],
            ),
          ),
          runId,
          timeout: _pageTimeout,
        );
        _checkRun(runId);
        if (albums.isEmpty) {
          _checkpointAssets.clear();
          _checkpointEntities.clear();
          _checkpointSignatures.clear();
          _hashAttempts.clear();
          _sizeAttempts.clear();
          _availableAssetCount = 0;
          await _finish(runId, refresh: false);
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
        if (page.length != end - _nextAssetOffset) {
          throw StateError('The album changed or a page could not be read.');
        }
        for (final entity in page) {
          _entities[entity.id] = entity;
          _checkpointEntities[entity.id] = entity;
          final previous = priorEntities[entity.id];
          final cached = priorAssets[entity.id];
          if (previous != null &&
              previous.modifiedDateTime == entity.modifiedDateTime &&
              cached != null &&
              _sameContentVersion(cached, entity)) {
            _setAsset(
              _sameDisplayMetadata(cached, entity)
                  ? cached
                  : _withCurrentMetadata(cached, entity),
            );
            final signature = priorSignatures[entity.id];
            if (signature != null) _signatures[entity.id] = signature;
          }
          if (!_assets.containsKey(entity.id)) {
            _checkpointSignatures.remove(entity.id);
            _hashAttempts.remove(entity.id);
            _sizeAttempts.remove(entity.id);
            _setAsset(
              PhotoAsset(
                id: entity.id,
                title: entity.title,
                width: entity.width,
                height: entity.height,
                size: 0,
                analysisPending: entity.type == AssetType.image,
                createDate: entity.createDateTime,
                modifiedDate: entity.modifiedDateTime,
                durationSeconds: entity.duration,
                type: entity.type,
                isScreenshot: _isScreenshot(entity),
              ),
            );
          }
        }
        _nextAssetOffset = end;
        _scanProgress = count == 0 ? 0.45 : 0.45 * end / count;
        // Counters remain live on every page; large snapshots are amortized.
        if (end == count || end == _assetPageSize || end % 960 == 0) {
          _publish();
        } else {
          notifyListeners();
        }
        await Future<void>.delayed(Duration.zero);
        _checkRun(runId);
      }
      _checkpointAssets.removeWhere((id, _) => !_assets.containsKey(id));
      _checkpointEntities.removeWhere((id, _) => !_entities.containsKey(id));
      _checkpointSignatures.removeWhere(
        (id, _) => !_signatures.containsKey(id),
      );
      _hashAttempts.removeWhere((id, _) => !_assets.containsKey(id));
      _sizeAttempts.removeWhere((id, _) => !_assets.containsKey(id));
      final ordered = _assets.values.toList()
        ..sort((a, b) => b.createDate.compareTo(a.createDate));
      _orderedIds = ordered.map((a) => a.id).toList();
      _currentPhase = ScanPhase.computingHashes;
      if (originals) {
        await _verifyLocalResources(runId, target, originalCandidates);
      } else {
        await _analyzeLocalPreviews(
          runId,
          retryEligibleIds: retryEligiblePreviewIds,
          roundBudget: previewRoundBudget,
        );
      }
      await _finish(
        runId,
        completed: originals || _previewRoundComplete(retryEligiblePreviewIds),
      );
    } on _RoundBudgetExpired {
      if (!_active(runId)) return;
      _cancelNative('$_instanceId:$runId:');
      _lastError = originals
          ? '本輪原始素材驗證已達 60 秒，結果已保留；再次驗證會先處理未嘗試項目。'
          : previewRoundBudget == _previewRoundBudget
          ? '本輪本機預覽分析已達 30 秒，結果已保留；繼續掃描會先處理未嘗試照片。'
          : '部分讀取逾時，已保留目前結果，可繼續掃描。';
      await _finish(runId, completed: false, refresh: false);
    } on _ScanCancelled {
      // cancelScan has already published a stable partial snapshot.
    } catch (error) {
      if (!_active(runId)) return;
      _lastError = error is TimeoutException
          ? '部分讀取逾時，已保留目前結果，可繼續掃描。'
          : '部分相簿讀取中斷，已保留目前結果，可繼續掃描。';
      await _finish(runId, completed: false, refresh: false);
    }
  }

  void _resetCounters() {
    _analyzedCount = _pendingCount = _attemptedCount = _cloudCount = 0;
    _verifiedCount = _pendingResourceCount = _attemptedResourceCount = 0;
    _knownSizeCount = _verifiedHashCount = 0;
    _knownLibraryBytes = 0;
  }

  void _countAsset(PhotoAsset asset, int direction) {
    if (asset.sizeKnown) {
      _knownSizeCount += direction;
      _knownLibraryBytes += direction * asset.size;
    }
    if (asset.type == AssetType.image) {
      if (asset.hash != null) _verifiedHashCount += direction;
      if (asset.analysisPending) {
        _pendingCount += direction;
      } else {
        _analyzedCount += direction;
      }
      if (asset.analysisAttempted) _attemptedCount += direction;
      if (asset.analysisPending && asset.pendingReason == 'not_local') {
        _cloudCount += direction;
      }
    }
    if (asset.resourceAnalysisAttempted) _attemptedResourceCount += direction;
    if (asset.resourceAnalysisPending) {
      _pendingResourceCount += direction;
    } else {
      _verifiedCount += direction;
    }
  }

  void _setAsset(PhotoAsset asset) {
    final old = _assets[asset.id];
    if (old != null) _countAsset(old, -1);
    _assets[asset.id] = asset;
    _checkpointAssets[asset.id] = asset;
    _countAsset(asset, 1);
  }

  void _setOperation(String operation) {
    _heartbeat?.cancel();
    _currentOperation = operation;
    _currentWaitSeconds = 0;
    _heartbeat = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed && _isScanning) {
        _currentWaitSeconds++;
        // Never rebuild a 42k-asset snapshot for a waiting heartbeat.
        notifyListeners();
      }
    });
  }

  void _startBudget(Duration duration) {
    _budgetReached = false;
    _budgetTimer = Timer(duration, () {
      _budgetReached = true;
      _abortWait?.call(_RoundBudgetExpired());
    });
    _snapshotClock.reset();
    _snapshotClock.start();
  }

  void _stopRound() {
    _heartbeat?.cancel();
    _budgetTimer?.cancel();
    _budgetReached = false;
    _isVerifyingOriginals = false;
    _currentOperation = null;
    _currentWaitSeconds = 0;
    _snapshotClock.stop();
  }

  Future<void> _publishAnalysisBatch(int runId, {bool first = false}) async {
    // Publish the first usable batch immediately. Rebuilding groups from a
    // large library on every preview batch can monopolize the round budget.
    if (first || _snapshotClock.elapsedMilliseconds >= 2000) {
      try {
        await _refreshGroups(runId);
      } on TimeoutException {
        // A slow visual grouping pass must not stop local preview or original
        // verification. Exact SHA groups and progress remain available.
        _checkRun(runId);
        _publish(groups: true);
      }
      _snapshotClock.reset();
    } else {
      notifyListeners();
    }
  }

  Future<void> _analyzeLocalPreviews(
    int runId, {
    required Set<String>? retryEligibleIds,
    required Duration roundBudget,
  }) async {
    if (!_nativeAvailable) return;
    final pending = _assets.values
        .where(
          (asset) => asset.type == AssetType.image && asset.analysisPending,
        )
        .toList();
    // Resume first covers the untouched tail instead of re-running slow/cloud
    // photos at the head. A later round can retry unavailable previews.
    final ids = [
      ...pending.where((asset) => !asset.analysisAttempted).map((a) => a.id),
      ...pending
          .where(
            (asset) =>
                asset.analysisAttempted &&
                (retryEligibleIds == null ||
                    retryEligibleIds.contains(asset.id)),
          )
          .map((a) => a.id),
    ];
    _startBudget(roundBudget);
    for (var offset = 0; offset < ids.length;) {
      _checkRun(runId);
      final batchStart = offset;
      final batchSize = offset == 0
          ? _firstPreviewBatchSize
          : _previewBatchSize;
      final batch = ids.sublist(
        offset,
        math.min(offset + batchSize, ids.length),
      );
      offset += batch.length;
      final token = '$_instanceId:$runId:preview:$batchStart';
      _setOperation('讀取本機預覽（${batch.length} 張）');
      Map<dynamic, dynamic>? data;
      try {
        data = await _awaitRun(
          _resourceChannel.invokeMapMethod<String, dynamic>('inspectPreviews', {
            'assetIds': batch,
            'token': token,
          }),
          runId,
          timeout: batch.length <= _firstPreviewBatchSize
              ? _previewTimeout
              : _widePreviewTimeout,
        );
      } on MissingPluginException {
        _nativeAvailable = false;
        break;
      } on TimeoutException {
        _cancelNative(token, exact: true);
      } on PlatformException {
        // An unavailable batch stays retryable; do not call the slow original API.
      }
      _checkRun(runId);
      final rows = <String, Map>{};
      final nativeRows = data?['assets'];
      if (nativeRows is List) {
        for (final row in nativeRows) {
          if (row is Map && batch.contains(row['assetId'])) {
            rows[row['assetId'] as String] = row;
          }
        }
      }
      final bytes = <String, Uint8List>{};
      final attemptedIds = <String>{};
      for (final id in batch) {
        final row = rows[id];
        // A channel failure or missing native row proves no request began.
        // Only native can distinguish an attempted timeout from a queued item.
        final status = row?['status'] as String? ?? 'not_started';
        final thumbnail = row?['thumbnail'];
        if (thumbnail is Uint8List && thumbnail.isNotEmpty) {
          bytes[id] = thumbnail;
        }
        final attempted = status != 'not_started' || bytes.containsKey(id);
        if (attempted) attemptedIds.add(id);
        _setAsset(
          _assets[id]!.copyWith(
            analysisAttempted: _assets[id]!.analysisAttempted || attempted,
            pendingReason: status,
          ),
        );
      }
      // Native may have queued fewer than 32 previews by its deadline. Those
      // never-started IDs remain fresh work for the next automatic round.
      retryEligibleIds?.removeAll(attemptedIds);
      // Attempts are visible even while the CPU worker is analyzing the bytes.
      _scanProgress =
          0.45 +
          0.55 * _attemptedCount / math.max(1, _analyzedCount + _pendingCount);
      notifyListeners();
      if (bytes.isNotEmpty) {
        _setOperation('分析本機預覽（${bytes.length} 張）');
        Map<String, Map<String, Object>> analyzed;
        try {
          analyzed = await _computeRun(
            _analyzeThumbnailBatch,
            bytes,
            runId,
            timeout: const Duration(seconds: 3),
          );
        } on TimeoutException {
          _checkRun(runId);
          for (final id in bytes.keys) {
            _setAsset(_assets[id]!.copyWith(pendingReason: 'analysis_timeout'));
          }
          await _publishAnalysisBatch(runId, first: batchStart == 0);
          continue;
        }
        _checkRun(runId);
        for (final entry in analyzed.entries) {
          final signature = ContentSignature.fromMap(entry.value);
          _signatures[entry.key] = signature;
          _checkpointSignatures[entry.key] = signature;
          final degraded = rows[entry.key]?['thumbnailDegraded'] == true;
          final quality =
              signature.isValid && !signature.isLowInformation && !degraded;
          _setAsset(
            _assets[entry.key]!.copyWith(
              analysisPending: !signature.isValid,
              previewDegraded: degraded,
              qualityScore: quality ? signature.qualityScore : 0,
              qualityReasons: degraded
                  ? const ['縮圖較粗糙，未提供畫面品質建議']
                  : signature.qualityReasons,
              isBlurry: quality && signature.isBlurry,
              isDark: quality && signature.isDark,
              isOverexposed: quality && signature.isOverexposed,
            ),
          );
        }
      }
      await _publishAnalysisBatch(runId, first: batchStart == 0);
      await Future<void>.delayed(Duration.zero);
      _checkRun(runId);
    }
  }

  bool _previewRoundComplete(Set<String>? retryEligibleIds) {
    if (!_nativeAvailable) return true;
    if (_attemptedCount < totalPhotoCount) return false;
    return retryEligibleIds == null ||
        !retryEligibleIds.any((id) => _assets[id]?.analysisPending == true);
  }

  List<String> _verificationQueue(
    OriginalVerificationTarget target,
    Set<String> candidates,
  ) {
    final pending = _assets.values.where((asset) {
      return switch (target) {
        OriginalVerificationTarget.all => asset.resourceAnalysisPending,
        OriginalVerificationTarget.exactPhotos =>
          asset.type == AssetType.image && asset.hash == null,
        OriginalVerificationTarget.fileSizes => !asset.sizeKnown,
      };
    }).toList();
    int? lastAttempt(PhotoAsset asset) =>
        target != OriginalVerificationTarget.fileSizes &&
            asset.type == AssetType.image
        ? _hashAttempts[asset.id]
        : _sizeAttempts[asset.id];
    var untouched = pending.where((a) => lastAttempt(a) == null).toList();
    final retries = pending.where((a) => lastAttempt(a) != null).toList()
      ..sort((a, b) => lastAttempt(a)!.compareTo(lastAttempt(b)!));
    if (target == OriginalVerificationTarget.fileSizes) {
      // When a user opens Large Files, the bounded first round should inspect
      // likely large, locally previewable files before known cloud misses.
      // Dimensions/duration are only queue hints; displayed bytes still need
      // a complete native size result.
      final originalOrder = <String, int>{
        for (var i = 0; i < untouched.length; i++) untouched[i].id: i,
      };
      int locality(PhotoAsset asset) => switch (asset.pendingReason) {
        'local' => 0,
        'not_local' => 2,
        _ => 1,
      };
      int sizeHint(PhotoAsset asset) =>
          asset.width * asset.height * math.max(1, asset.durationSeconds);
      untouched.sort((a, b) {
        final available = locality(a).compareTo(locality(b));
        if (available != 0) return available;
        final dimensions = sizeHint(b).compareTo(sizeHint(a));
        return dimensions != 0
            ? dimensions
            : originalOrder[a.id]!.compareTo(originalOrder[b.id]!);
      });
    }
    List<PhotoAsset> boundedPriority(
      List<PhotoAsset> preferred,
      List<PhotoAsset> other,
    ) {
      final queue = <PhotoAsset>[];
      var nextPreferred = 0;
      var nextOther = 0;
      while (nextPreferred < preferred.length || nextOther < other.length) {
        for (var i = 0; i < 3 && nextPreferred < preferred.length; i++) {
          queue.add(preferred[nextPreferred++]);
        }
        if (nextOther < other.length) queue.add(other[nextOther++]);
      }
      return queue;
    }

    if (target == OriginalVerificationTarget.exactPhotos) {
      // Metadata is only a scheduling hint; only complete original-resource SHA
      // results may form duplicate groups. Candidate retries do not take over
      // the fresh queue when their originals remain cloud-only.
      String metadataKey(PhotoAsset a) =>
          '${a.width}:${a.height}:${a.createDate.microsecondsSinceEpoch}';
      final metadataCounts = <String, int>{};
      for (final asset in _assets.values.where(
        (a) => a.type == AssetType.image,
      )) {
        metadataCounts.update(
          metadataKey(asset),
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
      final metadataHints = untouched
          .where((a) => metadataCounts[metadataKey(a)]! > 1)
          .map((a) => a.id)
          .toSet();
      final visual = untouched.where((a) => candidates.contains(a.id)).toList();
      final hints = untouched
          .where(
            (a) => !candidates.contains(a.id) && metadataHints.contains(a.id),
          )
          .toList();
      final ordinary = untouched
          .where(
            (a) => !candidates.contains(a.id) && !metadataHints.contains(a.id),
          )
          .toList();
      // Visual evidence outranks coincidental metadata, but even a very large
      // candidate tier must yield to ordinary fresh photographs. Neither tier
      // is proof of duplication; the complete original SHA remains mandatory.
      untouched = boundedPriority([...visual, ...hints], ordinary);
    }
    List<String> typeQueue(AssetType type) {
      final fresh = untouched.where((a) => a.type == type).toList();
      final old = retries.where((a) => a.type == type).toList();
      return boundedPriority(fresh, old).map((a) => a.id).toList();
    }

    // Each type has its own fair queue. A cancelled video can be retried even
    // when ten thousand photographs are still untouched. Within a type, three
    // fresh items alternate with the oldest retry so neither can starve.
    final videos = typeQueue(AssetType.video);
    final photos = typeQueue(AssetType.image);
    return [
      for (var i = 0; i < math.max(videos.length, photos.length); i++) ...[
        if (i < videos.length) videos[i],
        if (i < photos.length) photos[i],
      ],
    ];
  }

  Future<void> _verifyLocalResources(
    int runId,
    OriginalVerificationTarget target,
    Set<String> candidates,
  ) async {
    if (!_nativeAvailable) return;
    final ids = _verificationQueue(target, candidates);
    _originalRoundTotal = ids.length;
    _originalRoundProcessed = 0;
    notifyListeners();
    _startBudget(_resourceRoundBudget);
    var processed = 0;
    for (final id in ids) {
      _checkRun(runId);
      final previous = _assets[id]!;
      final includeHash =
          target != OriginalVerificationTarget.fileSizes &&
          previous.type == AssetType.image;
      final sequence = ++_resourceAttemptSequence;
      if (includeHash) _hashAttempts[id] = sequence;
      if (!includeHash || !previous.sizeKnown) _sizeAttempts[id] = sequence;
      // Persist attempts before awaiting native work. A round deadline or a
      // cancellation must not cause the next round to retry the same slow head.
      _setAsset(previous.copyWith(resourceAnalysisAttempted: true));
      _setOperation('驗證本機原始素材');
      notifyListeners();
      _checkRun(runId);
      final token = '$_instanceId:$runId:original:$id';
      Map<dynamic, dynamic>? data;
      try {
        data = await _awaitRun(
          _resourceChannel.invokeMapMethod<String, dynamic>('inspectAsset', {
            'assetId': id,
            'token': token,
            'includeHash': includeHash,
            'includeThumbnail': false,
            'resourceTimeoutMs': 4000,
            // Size-only streams count bytes with constant memory. They still
            // have a finite byte ceiling and the native four-second deadline.
            'maxBytes': includeHash
                ? 512 * 1024 * 1024
                : 8 * 1024 * 1024 * 1024,
          }),
          runId,
          timeout: _resourceTimeout,
        );
      } on MissingPluginException {
        _nativeAvailable = false;
        break;
      } on TimeoutException {
        _cancelNative(token, exact: true);
      } on PlatformException {
        // Never treat a partial stream as verified size or content.
      }
      _checkRun(runId);
      final size = data?['size'];
      final hash = data?['hash'];
      final reason = data?['pendingReason'] is String
          ? data!['pendingReason'] as String
          : null;
      final invalidated = const {
        'asset_changed_during_analysis',
        'asset_unavailable',
        'no_resources',
        'unknown_resource_type',
        'original_resource_missing',
        'live_photo_pair_missing',
        'edited_photo_render_missing',
        'edited_video_render_missing',
        'edited_live_pair_missing',
      }.contains(reason);
      final known =
          !invalidated &&
          (data?['complete'] == true || data?['sizeComplete'] == true) &&
          data?['sizeKnown'] == true &&
          size is int &&
          size > 0;
      final verifiedHash =
          includeHash &&
              known &&
              data?['complete'] == true &&
              data?['hashComplete'] != false &&
              hash is String &&
              RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)
          ? hash
          : null;
      final hasKnownSize = known || (previous.sizeKnown && !invalidated);
      final retainedHash = !includeHash && !invalidated
          ? previous.hash
          : verifiedHash;
      final needsHash =
          previous.type == AssetType.image && retainedHash == null;
      final resourcePending = !hasKnownSize || needsHash;
      _setAsset(
        _assets[id]!.copyWith(
          size: known ? size : (hasKnownSize ? previous.size : 0),
          sizeKnown: hasKnownSize,
          hash: retainedHash,
          clearHash: retainedHash == null,
          resourceAnalysisAttempted: true,
          resourcePendingReason:
              reason ??
              (hasKnownSize && needsHash ? 'hash_pending' : 'resource_timeout'),
          clearResourcePendingReason: !resourcePending,
          resourceAnalysisPending: resourcePending,
        ),
      );
      processed++;
      _originalRoundProcessed = processed;
      _scanProgress = 0.45 + 0.55 * processed / math.max(1, ids.length);
      await _publishAnalysisBatch(runId, first: processed == 1);
      await Future<void>.delayed(Duration.zero);
      _checkRun(runId);
    }
  }

  /// A single bounded worker, killed on cancellation/deadline. Unlike an
  /// abandoned compute Future it cannot accumulate expensive old group runs.
  Future<R> _computeRun<Q, R>(
    R Function(Q) callback,
    Q message,
    int runId, {
    required Duration timeout,
  }) async {
    _checkRun(runId);
    final reply = ReceivePort();
    final result = Completer<R>();
    final subscription = reply.listen((dynamic envelope) {
      if (result.isCompleted) return;
      final values = envelope as List;
      if (values[0] == true) {
        result.complete(values[1] as R);
      } else {
        result.completeError(StateError(values[1].toString()));
      }
    });
    Isolate? worker;
    try {
      worker = await Isolate.spawn(_analysisWorker, <Object>[
        reply.sendPort,
        callback,
        message as Object,
      ]);
      return await _awaitRun(result.future, runId, timeout: timeout);
    } finally {
      worker?.kill(priority: Isolate.immediate);
      await subscription.cancel();
      reply.close();
    }
  }

  Future<T> _awaitRun<T>(Future<T> future, int runId, {Duration? timeout}) {
    _checkRun(runId);
    final result = Completer<T>();
    Timer? timer;
    late void Function(Object) abort;
    void fail(Object error, [StackTrace? stack]) {
      if (result.isCompleted) return;
      timer?.cancel();
      if (identical(_abortWait, abort)) _abortWait = null;
      result.completeError(error, stack);
    }

    abort = (error) => fail(error);
    _abortWait = abort;
    if (timeout != null) {
      timer = Timer(
        timeout,
        () => fail(TimeoutException('Photo operation timed out', timeout)),
      );
    }
    future.then((value) {
      if (result.isCompleted) return;
      timer?.cancel();
      if (identical(_abortWait, abort)) _abortWait = null;
      result.complete(value);
    }, onError: (Object error, StackTrace stack) => fail(error, stack));

    return result.future;
  }

  bool _active(int runId) => !_disposed && _isScanning && _scanRunId == runId;
  void _checkRun(int runId) {
    if (!_active(runId)) throw _ScanCancelled();
    if (_budgetReached) throw _RoundBudgetExpired();
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

  Future<void> _finish(
    int runId, {
    bool completed = true,
    bool refresh = true,
  }) async {
    if (!_active(runId)) return;
    if (refresh) await _refreshGroups(runId);
    if (!_active(runId)) return;
    _hasCompletedScan = completed;
    _isScanning = false;
    _stopRound();
    _abortWait?.call(_ScanCancelled());
    _abortWait = null;
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
    _drainPhotoAccessRefresh();
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
        final preview = (a.previewDegraded ? 1 : 0).compareTo(
          b.previewDegraded ? 1 : 0,
        );
        if (preview != 0) return preview;
        final quality = (b.qualityScore ?? -1).compareTo(a.qualityScore ?? -1);
        if (quality != 0) return quality;
        final resolution = (b.width * b.height).compareTo(a.width * a.height);
        return resolution != 0 ? resolution : a.id.compareTo(b.id);
      });

  List<DuplicateGroup> _exactGroups(Iterable<PhotoAsset> assets) {
    final buckets = <String, List<PhotoAsset>>{};
    for (final asset in assets) {
      if (asset.type == AssetType.image &&
          asset.sizeKnown &&
          asset.hash != null) {
        buckets.putIfAbsent(asset.hash!, () => []).add(asset);
      }
    }
    return buckets.entries.where((entry) => entry.value.length > 1).map((
      entry,
    ) {
      final ordered = _recommended(entry.value);
      return DuplicateGroup(
        hash: entry.key,
        assets: ordered,
        bestAssetId: ordered.first.id,
        bestReason: _bestReason(ordered.first, exact: true),
      );
    }).toList();
  }

  Future<void> _refreshGroups(int runId) async {
    _checkRun(runId);
    final assets = _assets.values.toList();
    final duplicateGroups = _exactGroups(assets);
    var similarGroups = <SimilarGroup>[];
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
    if (candidates.length >= 2) _setOperation('整理視覺相似候選');
    final groupedIds = candidates.length < 2
        ? <List<String>>[]
        : await _computeRun(
            groupSimilarPhotos,
            candidates,
            runId,
            timeout: const Duration(seconds: 5),
          );
    _checkRun(runId);
    similarGroups = groupedIds.map((ids) {
      final ordered = _recommended(ids.map((id) => _assets[id]!).toList());
      final distance = visualDistance(
        _signatures[ordered[0].id]!,
        _signatures[ordered[1].id]!,
      );
      return SimilarGroup(
        assets: ordered,
        hammingDistance: distance ?? 0,
        bestAssetId: ordered.any((a) => !a.previewDegraded)
            ? ordered.first.id
            : null,
        bestReason: ordered.any((a) => !a.previewDegraded)
            ? _bestReason(ordered.first, exact: false)
            : null,
      );
    }).toList();
    _checkRun(runId);
    _duplicateGroups = duplicateGroups;
    _similarGroups = similarGroups;
    _publish();
  }

  void _publish({bool groups = false}) {
    if (_disposed) return;
    final assets = _orderedIds == null
        ? _assets.values.toList()
        : _orderedIds!
              .map((id) => _assets[id])
              .whereType<PhotoAsset>()
              .toList();
    var duplicateGroups = _duplicateGroups;
    var similarGroups = _similarGroups;
    if (groups) {
      // A deadline/cancel may occur between throttled group refreshes. Publish
      // every completed SHA pair without starting an uncancellable visual job.
      duplicateGroups = _exactGroups(assets);
      final exactIds = duplicateGroups
          .expand((group) => group.assets)
          .map((a) => a.id)
          .toSet();
      similarGroups = similarGroups
          .map((group) {
            final remaining = group.assets
                .map((a) => _assets[a.id])
                .whereType<PhotoAsset>()
                .where((a) => !exactIds.contains(a.id))
                .toList();
            if (remaining.length < 2) return null;
            final eligible = remaining
                .where((a) => !a.previewDegraded)
                .toList();
            final keep = eligible.any((a) => a.id == group.bestAssetId)
                ? group.bestAssetId
                : (eligible.isEmpty ? null : eligible.first.id);
            return SimilarGroup(
              assets: remaining,
              hammingDistance: group.hammingDistance,
              bestAssetId: keep,
              bestReason: keep == null ? null : group.bestReason,
            );
          })
          .whereType<SimilarGroup>()
          .toList();
      _duplicateGroups = duplicateGroups;
      _similarGroups = similarGroups;
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
    final ids = <String>{
      for (final asset in assets)
        if (_assets[asset.id] case final current?)
          if (current.modifiedDate == asset.modifiedDate &&
              current.createDate == asset.createDate &&
              current.width == asset.width &&
              current.height == asset.height &&
              current.type == asset.type)
            asset.id,
    };
    if (_disposed || isScanning || _isDeleting || ids.isEmpty) return {};
    _isDeleting = true;
    notifyListeners();
    try {
      final result = await PhotoManager.editor.deleteWithIds(ids.toList());
      final deleted = result.toSet().intersection(ids);
      if (_disposed) return deleted;
      final indexedDeleted = deleted.where(_assets.containsKey).length;
      for (final id in deleted) {
        final removed = _assets.remove(id);
        if (removed != null) _countAsset(removed, -1);
        _entities.remove(id);
        _signatures.remove(id);
        _checkpointAssets.remove(id);
        _checkpointEntities.remove(id);
        _checkpointSignatures.remove(id);
        _hashAttempts.remove(id);
        _sizeAttempts.remove(id);
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
      _drainPhotoAccessRefresh();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    final prefix = '$_instanceId:$_scanRunId:';
    _disposed = true;
    _isScanning = false;
    _stopRound();
    _scanRunId++;
    _abortWait?.call(_ScanCancelled());
    _abortWait = null;
    _cancelNative(prefix);
    _assets.clear();
    _entities.clear();
    _signatures.clear();
    _checkpointAssets.clear();
    _checkpointEntities.clear();
    _checkpointSignatures.clear();
    _hashAttempts.clear();
    _sizeAttempts.clear();
    _duplicateGroups = [];
    _similarGroups = [];
    _orderedIds = null;
    _scanResult = ScanResult.empty;
    _resetCounters();
    super.dispose();
  }
}
