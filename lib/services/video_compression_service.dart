import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_compress/video_compress.dart';

class PreparedVideo {
  final File original;
  final File output;
  final int originalBytes;
  final int outputBytes;
  const PreparedVideo({
    required this.original,
    required this.output,
    required this.originalBytes,
    required this.outputBytes,
  });
  int get savedBytes => originalBytes - outputBytes;
}

abstract class VideoCompressionBackend {
  Future<File> load(String assetId);
  Future<MediaInfo> inspect(File file);
  Future<File?> encode(File file, void Function(double) onProgress);
  Future<Directory> temporaryDirectory();
  Future<String> save(File file);
  Future<void> cancel();
  Future<void> releaseEncoded(File file, File original) async {}
}

class DeviceVideoCompressionBackend implements VideoCompressionBackend {
  DeviceVideoCompressionBackend({bool? isIos})
    : _isIos = isIos ?? Platform.isIOS;
  final bool _isIos;
  static const _mediaChannel = MethodChannel('cleanup/photo_resources');
  static bool _encoderActive = false;
  bool _encodingSessionActive = false;
  bool _nativeEncoding = false;
  bool _cancelRequested = false;
  @override
  Future<File> load(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null || asset.type != AssetType.video) {
      throw StateError('找不到這段影片，請重新掃描。');
    }
    if ((_isIos || Platform.isMacOS) && !await asset.isLocallyAvailable()) {
      throw StateError('影片尚在 iCloud，請先在照片 App 下載原片後重試。');
    }
    final file = await asset.file;
    if (file == null) throw StateError('影片無法讀取。');
    return file;
  }

  @override
  Future<MediaInfo> inspect(File file) => VideoCompress.getMediaInfo(file.path);

  @override
  Future<File?> encode(File file, void Function(double) onProgress) async {
    if (_encoderActive || VideoCompress.isCompressing) {
      throw StateError('前一次壓縮仍在結束，請稍後重試。');
    }
    _encoderActive = true;
    _encodingSessionActive = true;
    _cancelRequested = false;
    Directory? pluginDirectory;
    Set<String> before = {};
    File? staging;
    final subscription = VideoCompress.compressProgress$.subscribe(
      (value) => onProgress(value / 100),
    );
    try {
      if (_isIos) {
        final path = await _mediaChannel.invokeMethod<String>(
          'compressionCacheDirectory',
          {},
        );
        if (path == null) throw StateError('無法取得影片暫存位置。');
        pluginDirectory = Directory(path);
      } else if (Platform.isAndroid) {
        final external = await getExternalStorageDirectory();
        if (external == null) throw StateError('無法取得影片暫存位置。');
        pluginDirectory = Directory('${external.path}/video_compress');
      } else {
        throw StateError('此裝置尚未支援影片壓縮。');
      }
      if (await pluginDirectory.exists()) {
        before = pluginDirectory
            .listSync(followLinks: false)
            .whereType<File>()
            .map((value) => value.absolute.path)
            .toSet();
      }
      if (_cancelRequested) return null;
      MediaInfo? info;
      _nativeEncoding = true;
      try {
        info = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
      } finally {
        _nativeEncoding = false;
      }
      final encoded = info?.file;
      if (info == null || info.isCancel == true || encoded == null) return null;
      final originalPath = await file.resolveSymbolicLinks();
      final encodedPath = await encoded.resolveSymbolicLinks();
      if (encodedPath == originalPath ||
          File(encodedPath).parent.path !=
              await pluginDirectory.resolveSymbolicLinks()) {
        throw StateError('壓縮輸出位置不符，原片已保留。');
      }
      final cache = await temporaryDirectory();
      staging = File(
        '${cache.path}/cleanup_encoded_${DateTime.now().microsecondsSinceEpoch}.mp4',
      );
      await encoded.copy(staging.path);
      return staging;
    } catch (_) {
      if (staging != null) await releaseEncoded(staging, file);
      rethrow;
    } finally {
      subscription.unsubscribe();
      if (pluginDirectory != null) {
        await _cleanupNewPluginFiles(pluginDirectory, before, file);
      }
      _encoderActive = false;
      _encodingSessionActive = false;
    }
  }

  Future<void> _cleanupNewPluginFiles(
    Directory directory,
    Set<String> before,
    File original,
  ) async {
    try {
      if (!await directory.exists()) return;
      final root = await directory.resolveSymbolicLinks();
      final source = await original.resolveSymbolicLinks();
      for (final candidate
          in directory.listSync(followLinks: false).whereType<File>()) {
        if (before.contains(candidate.absolute.path)) continue;
        final path = await candidate.resolveSymbolicLinks();
        if (path == source || File(path).parent.path != root) continue;
        if (RegExp(
          r'\.(mp4|mov|m4v|3gp)$',
          caseSensitive: false,
        ).hasMatch(path)) {
          await candidate.delete();
        }
      }
    } catch (_) {
      // Cleanup cannot change the result of a settled native export.
    }
  }

  @override
  Future<void> releaseEncoded(File file, File original) async {
    try {
      if (!await file.exists()) return;
      final path = await file.resolveSymbolicLinks();
      final root = await (await temporaryDirectory()).resolveSymbolicLinks();
      if (File(path).parent.path == root &&
          path != await original.resolveSymbolicLinks() &&
          file.uri.pathSegments.last.startsWith('cleanup_encoded_')) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Future<Directory> temporaryDirectory() => getTemporaryDirectory();

  @override
  Future<String> save(File file) async {
    if (_isIos) {
      final id = await _mediaChannel.invokeMethod<String>(
        'saveCompressedVideo',
        {'path': file.path},
      );
      if (id == null || id.isEmpty) throw StateError('無法確認另存結果，請先到照片 App 檢查。');
      return id;
    }
    return (await PhotoManager.editor.saveVideo(
      file,
      title: 'Cleanup_${DateTime.now().millisecondsSinceEpoch}.mp4',
    )).id;
  }

  @override
  Future<void> cancel() async {
    if (!_encodingSessionActive) return;
    _cancelRequested = true;
    if (_nativeEncoding) await VideoCompress.cancelCompression();
  }
}

/// Creates a separate preview copy. Saving never deletes the source asset.
class VideoCompressionService extends ChangeNotifier {
  VideoCompressionService({
    VideoCompressionBackend? backend,
    Duration encodingTimeout = const Duration(minutes: 10),
  }) : _backend = backend ?? DeviceVideoCompressionBackend(),
       _encodingTimeout = encodingTimeout;

  final VideoCompressionBackend _backend;
  final Duration _encodingTimeout;
  bool _busy = false;
  bool _saving = false;
  bool _disposed = false;
  bool _cancelled = false;
  bool _encoding = false;
  bool _nativeCancelSent = false;
  int _runId = 0;
  double _progress = 0;
  PreparedVideo? _prepared;
  String? _savedAssetId;

  bool get isBusy => _busy || _saving;
  bool get isSaving => _saving;
  double get progress => _progress;
  PreparedVideo? get prepared => _prepared;
  String? get savedAssetId => _savedAssetId;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _checkActive() {
    if (_disposed || _cancelled) throw StateError('已取消壓縮。');
  }

  Future<PreparedVideo> prepare(String assetId) async {
    if (_disposed || isBusy || _prepared != null) {
      throw StateError('請先完成目前的影片操作。');
    }
    _busy = true;
    final runId = ++_runId;
    _cancelled = false;
    _nativeCancelSent = false;
    _progress = 0;
    _notify();
    File? ownedCopy;
    File? encoded;
    File? original;
    try {
      original = await _backend
          .load(assetId)
          .timeout(const Duration(seconds: 60));
      _checkActive();
      final originalBytes = await original.length();
      if (originalBytes <= 0) throw StateError('原片為空，無法壓縮。');
      final sourceInfo = await _backend
          .inspect(original)
          .timeout(const Duration(seconds: 30));
      _checkActive();
      _validateMedia(sourceInfo);
      _encoding = true;
      try {
        final source = original;
        final encoding = _backend.encode(source, (value) {
          if (!_disposed && !_cancelled && runId == _runId) {
            _progress = value.clamp(0.0, 1.0) * 0.9;
            _notify();
          }
        });
        unawaited(
          encoding.then<void>((output) async {
            if (output != null &&
                (_disposed || _cancelled || runId != _runId)) {
              await _backend.releaseEncoded(output, source);
            }
          }, onError: (Object _) {}),
        );
        encoded = await encoding.timeout(_encodingTimeout);
      } on TimeoutException {
        _cancelled = true;
        await _cancelEncoderOnce();
        rethrow;
      } finally {
        _encoding = false;
      }
      _checkActive();
      if (encoded == null) throw StateError('壓縮未完成，原片已保留。');
      if (await encoded.resolveSymbolicLinks() ==
          await original.resolveSymbolicLinks()) {
        throw StateError('壓縮未產生獨立副本，原片已保留。');
      }
      final directory = await _backend.temporaryDirectory();
      _checkActive();
      final name =
          'cleanup_preview_${DateTime.now().microsecondsSinceEpoch}.mp4';
      ownedCopy = File('${directory.path}${Platform.pathSeparator}$name');
      await encoded.copy(ownedCopy.path);
      _checkActive();
      final outputBytes = await ownedCopy.length();
      if (outputBytes <= 0 || outputBytes >= originalBytes) {
        throw StateError('這段影片壓縮後沒有變小，原片已保留。');
      }
      final outputInfo = await _backend
          .inspect(ownedCopy)
          .timeout(const Duration(seconds: 30));
      _checkActive();
      _validateMedia(outputInfo);
      final durationGap = (sourceInfo.duration! - outputInfo.duration!).abs();
      if (durationGap > math.max(1000, sourceInfo.duration! * 0.02)) {
        throw StateError('壓縮後長度不符，原片已保留。');
      }
      _prepared = PreparedVideo(
        original: original,
        output: ownedCopy,
        originalBytes: originalBytes,
        outputBytes: outputBytes,
      );
      _progress = 1;
      return _prepared!;
    } catch (_) {
      if (ownedCopy != null) await _removePreview(ownedCopy);
      rethrow;
    } finally {
      if (encoded != null && original != null) {
        await _backend.releaseEncoded(encoded, original);
      }
      _busy = false;
      _notify();
    }
  }

  void _validateMedia(MediaInfo info) {
    if ((info.duration ?? 0) <= 0 ||
        (info.width ?? 0) <= 0 ||
        (info.height ?? 0) <= 0) {
      throw StateError('無法驗證影片內容，原片已保留。');
    }
  }

  Future<String> savePrepared() async {
    if (_disposed || isBusy || _prepared == null) {
      throw StateError('請先完成壓縮與預覽。');
    }
    if (_savedAssetId != null) return _savedAssetId!;
    _saving = true;
    _notify();
    try {
      // A native save is not timed out: retrying an unresolved write could
      // silently create multiple copies. The UI stays busy until it settles.
      final id = await _backend.save(_prepared!.output);
      if (id.isEmpty) throw StateError('另存失敗，原片已保留，請重試。');
      _savedAssetId = id;
      return id;
    } finally {
      _saving = false;
      if (_disposed && _prepared != null) {
        await _removePreview(_prepared!.output);
      }
      _notify();
    }
  }

  Future<void> cancel() async {
    if (_saving) return;
    _cancelled = true;
    await _cancelEncoderOnce();
    _notify();
  }

  Future<void> _cancelEncoderOnce() async {
    if (!_encoding || _nativeCancelSent) return;
    _nativeCancelSent = true;
    try {
      await _backend.cancel();
    } catch (_) {}
  }

  Future<void> _removePreview(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _runId++;
    _cancelled = true;
    if (_encoding) unawaited(_cancelEncoderOnce());
    final output = _prepared?.output;
    // Never remove a file while a native save still reads it.
    if (output != null && !_saving) unawaited(_removePreview(output));
    super.dispose();
  }
}
