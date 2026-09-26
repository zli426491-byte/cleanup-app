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
      final entity = await AssetEntity.fromId(
        id,
      ).timeout(const Duration(milliseconds: 800), onTimeout: () => null);
      if (entity == null) return null;
      return await entity
          .thumbnailDataWithSize(
            ThumbnailSize(size, size),
            format: ThumbnailFormat.jpeg,
          )
          .timeout(const Duration(milliseconds: 1200), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnail,
      builder: (context, snapshot) {
        final bytes = snapshot.connectionState == ConnectionState.done
            ? snapshot.data ?? widget.asset.thumbnail
            : widget.asset.thumbnail;
        if (bytes != null) {
          return Image.memory(bytes, fit: BoxFit.cover);
        }

        return Container(
          color: Colors.grey[100],
          child: Icon(
            widget.asset.type == AssetType.video
                ? Icons.videocam_rounded
                : Icons.image_rounded,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}
