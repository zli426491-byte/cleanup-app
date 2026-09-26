import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../services/photo_scanner_service.dart';

class AssetThumbnail extends StatefulWidget {
  final PhotoAsset asset;
  final int previewSize;

  const AssetThumbnail({
    super.key,
    required this.asset,
    this.previewSize = 220,
  });

  @override
  State<AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<AssetThumbnail> {
  static const _maxCacheEntries = 120;
  static const _requestTimeout = Duration(seconds: 30);
  static final Map<String, Future<Uint8List?>> _cache = {};

  late Future<Uint8List?> _thumbnail;

  @override
  void initState() {
    super.initState();
    _thumbnail = _thumbnailFor(widget.asset, widget.previewSize);
  }

  @override
  void didUpdateWidget(AssetThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id ||
        oldWidget.previewSize != widget.previewSize) {
      _thumbnail = _thumbnailFor(widget.asset, widget.previewSize);
    }
  }

  static Future<Uint8List?> _thumbnailFor(PhotoAsset asset, int size) {
    if (asset.thumbnail != null) return Future.value(asset.thumbnail);
    final key = '${asset.id}:$size';
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    while (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    final future = _loadThumbnail(asset.id, size);
    _cache[key] = future;
    future.then((bytes) {
      if (bytes == null && identical(_cache[key], future)) _cache.remove(key);
    });
    return future;
  }

  static Future<Uint8List?> _loadThumbnail(String id, int size) async {
    try {
      return await _requestThumbnail(
        id,
        size,
      ).timeout(_requestTimeout, onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _requestThumbnail(String id, int size) async {
    final entity = await AssetEntity.fromId(id);
    if (entity == null) return null;
    return entity.thumbnailDataWithSize(
      ThumbnailSize(size, size),
      format: ThumbnailFormat.jpeg,
    );
  }

  void _retry() {
    _cache.remove('${widget.asset.id}:${widget.previewSize}');
    setState(() {
      _thumbnail = _thumbnailFor(widget.asset, widget.previewSize);
    });
  }

  Widget _retryButton() => Center(
    child: IconButton(
      tooltip: '重新載入預覽',
      onPressed: _retry,
      icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnail,
      builder: (context, snapshot) {
        final bytes = snapshot.connectionState == ConnectionState.done
            ? snapshot.data ?? widget.asset.thumbnail
            : widget.asset.thumbnail;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _retryButton(),
          );
        }

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
