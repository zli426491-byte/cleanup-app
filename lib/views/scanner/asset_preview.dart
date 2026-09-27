import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import '../../services/photo_scanner_service.dart';
import '../../services/video_compression_service.dart';
import '../components/video_playback_controls.dart';
import 'asset_thumbnail.dart';
import 'photo_asset_labels.dart';

Future<void> showAssetPreview(BuildContext context, PhotoAsset asset) =>
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.65,
                  child: AssetPreviewContent(asset: asset),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  context.l10n.assetPreviewDetails(
                    asset.width,
                    asset.height,
                    assetSizeLabel(asset, context: context),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.scanBackToCompare),
              ),
            ],
          ),
        ),
      ),
    );

class AssetPreviewContent extends StatefulWidget {
  const AssetPreviewContent({
    super.key,
    required this.asset,
    this.videoFileLoader,
    this.controllerFactory,
  });
  final PhotoAsset asset;
  final Future<File> Function(PhotoAsset asset)? videoFileLoader;
  final VideoPlayerController Function(File file)? controllerFactory;
  @override
  State<AssetPreviewContent> createState() => _AssetPreviewContentState();
}

class _AssetPreviewContentState extends State<AssetPreviewContent> {
  VideoPlayerController? _player;
  bool _loading = false;
  bool _failed = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    if (widget.asset.type == AssetType.video) _loadVideo();
  }

  Future<void> _loadVideo() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final previous = _player;
    _player = null;
    previous?.removeListener(_playerChanged);
    await previous?.dispose();
    VideoPlayerController? player;
    try {
      final file =
          await (widget.videoFileLoader?.call(widget.asset) ??
                  DeviceVideoCompressionBackend().load(widget.asset.id))
              .timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation) return;
      player =
          widget.controllerFactory?.call(file) ??
          VideoPlayerController.file(file);
      await player.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation) {
        await player.dispose();
        return;
      }
      _player = player;
      player.addListener(_playerChanged);
      setState(() {
        _loading = false;
        _failed = player!.value.hasError;
      });
    } catch (_) {
      await player?.dispose();
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _playerChanged() {
    if (mounted && _player?.value.hasError == true && !_failed) {
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _generation++;
    _player?.removeListener(_playerChanged);
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asset.type != AssetType.video) {
      return InteractiveViewer(
        child: AssetThumbnail(
          asset: widget.asset,
          previewSize: 1200,
          fullImage: true,
        ),
      );
    }
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            Text(context.l10n.assetVideoLoading),
          ],
        ),
      );
    }
    if (_failed || _player == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.assetVideoUnavailable,
              textAlign: TextAlign.center,
            ),
            IconButton(
              tooltip: context.l10n.assetReloadPreview,
              onPressed: _loadVideo,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _player!.value.aspectRatio,
              child: VideoPlayer(_player!),
            ),
          ),
        ),
        VideoPlaybackControls(
          controller: _player!,
          onError: () {
            if (mounted) setState(() => _failed = true);
          },
        ),
      ],
    );
  }
}
