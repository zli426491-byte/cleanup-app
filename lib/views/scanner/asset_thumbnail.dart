import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../services/photo_scanner_service.dart';

class AssetThumbnail extends StatefulWidget {
  final PhotoAsset asset;
  final int previewSize;
  final bool fullImage;
  final ValueChanged<bool>? onPreviewReady;

  const AssetThumbnail({
    super.key,
    required this.asset,
    this.previewSize = 220,
    this.fullImage = false,
    this.onPreviewReady,
  });

  @override
  State<AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<AssetThumbnail> {
  static const _maxCacheEntries = 120;
  static const _requestTimeout = Duration(seconds: 30);
  static final Map<(PhotoAsset, int, bool), Future<Uint8List?>> _cache = {};

  late Future<Uint8List?> _thumbnail;
  int _generation = 0;
  bool? _reportedReady;
  bool _forceNative = false;

  @override
  void initState() {
    super.initState();
    _thumbnail = _thumbnailFor(
      widget.asset,
      widget.previewSize,
      widget.fullImage,
    );
  }

  @override
  void didUpdateWidget(AssetThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.asset, widget.asset) ||
        oldWidget.previewSize != widget.previewSize ||
        oldWidget.fullImage != widget.fullImage ||
        oldWidget.asset.thumbnail != widget.asset.thumbnail) {
      _generation++;
      _forceNative = false;
      _reportedReady = null;
      _thumbnail = _thumbnailFor(
        widget.asset,
        widget.previewSize,
        widget.fullImage,
      );
    }
  }

  static Future<Uint8List?> _thumbnailFor(
    PhotoAsset asset,
    int size,
    bool fullImage, {
    bool ignoreEmbedded = false,
  }) {
    // A grid sample may already be cropped. Never use it as the full preview.
    if (!ignoreEmbedded && !fullImage && asset.thumbnail != null) {
      return Future.value(asset.thumbnail);
    }
    final key = (asset, size, fullImage);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    while (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    final future = _loadThumbnail(asset.id, size, fullImage);
    _cache[key] = future;
    future.then((bytes) {
      if (bytes == null && identical(_cache[key], future)) _cache.remove(key);
    });
    return future;
  }

  static Future<Uint8List?> _loadThumbnail(
    String id,
    int size,
    bool fullImage,
  ) async {
    try {
      return await _requestThumbnail(
        id,
        size,
        fullImage,
      ).timeout(_requestTimeout, onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _requestThumbnail(
    String id,
    int size,
    bool fullImage,
  ) async {
    final entity = await AssetEntity.fromId(id);
    if (entity == null) return null;
    return entity.thumbnailDataWithOption(
      ThumbnailOption.ios(
        size: ThumbnailSize(size, size),
        format: ThumbnailFormat.jpeg,
        resizeContentMode: fullImage
            ? ResizeContentMode.fit
            : ResizeContentMode.fill,
      ),
    );
  }

  void _retry() {
    _cache.remove((widget.asset, widget.previewSize, widget.fullImage));
    _generation++;
    _forceNative = true;
    _reportedReady = null;
    setState(() {
      _thumbnail = _thumbnailFor(
        widget.asset,
        widget.previewSize,
        widget.fullImage,
        ignoreEmbedded: true,
      );
    });
  }

  void _reportReady(bool ready) {
    if (_reportedReady == ready) return;
    _reportedReady = ready;
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _generation && _reportedReady == ready) {
        widget.onPreviewReady?.call(ready);
      }
    });
  }

  Widget _retryButton() => Center(
    child: IconButton(
      tooltip: context.l10n.assetReloadPreview,
      onPressed: _retry,
      icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnail,
      builder: (context, snapshot) {
        final fallback = widget.fullImage || _forceNative
            ? null
            : widget.asset.thumbnail;
        final bytes = snapshot.connectionState == ConnectionState.done
            ? snapshot.data ?? fallback
            : fallback;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: widget.fullImage ? BoxFit.contain : BoxFit.cover,
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, synchronous) {
              _reportReady(frame != null);
              return child;
            },
            errorBuilder: (_, _, _) {
              _reportReady(false);
              return _retryButton();
            },
          );
        }
        _reportReady(false);
        return Container(
          color: Colors.grey[100],
          child: snapshot.connectionState != ConnectionState.done
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _retryButton(),
        );
      },
    );
  }
}
