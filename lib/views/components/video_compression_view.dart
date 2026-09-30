import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cleanup_app/l10n/l10n.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../services/photo_scanner_service.dart';
import '../../services/subscription_manager.dart';
import '../../services/video_compression_service.dart';
import '../../utils/app_theme.dart';
import 'video_playback_controls.dart';

class VideoCompressionView extends StatefulWidget {
  final PhotoAsset asset;
  final VideoCompressionService? service;
  final VideoPlayerController Function(File file)? controllerFactory;
  const VideoCompressionView({
    super.key,
    required this.asset,
    this.service,
    this.controllerFactory,
  });

  @override
  State<VideoCompressionView> createState() => _VideoCompressionViewState();
}

class _VideoCompressionViewState extends State<VideoCompressionView> {
  late final VideoCompressionService _service;
  VideoPlayerController? _player;
  bool _initializingPreview = false;
  bool _resettingPreset = false;
  bool _savingRequested = false;
  bool _showOriginal = false;
  String? _error;
  bool _cancelRequested = false;
  int _previewGeneration = 0;
  VideoCompressionPreset _preset = VideoCompressionPreset.balanced;

  bool get _busy =>
      _service.isBusy ||
      _initializingPreview ||
      _resettingPreset ||
      _savingRequested;
  bool get _canLeave =>
      !_busy || (_cancelRequested && !_service.isSaving && !_savingRequested);

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? VideoCompressionService();
  }

  @override
  void dispose() {
    _previewGeneration++;
    _player?.removeListener(_onPlayerChanged);
    _player?.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    if (_busy || !context.read<SubscriptionManager>().isPro) return;
    setState(() {
      _error = null;
      _cancelRequested = false;
    });
    try {
      final prepared = await _service.prepare(widget.asset.id, preset: _preset);
      if (!mounted || _cancelRequested) return;
      await _loadPreview(prepared.output, original: false);
    } catch (error) {
      if (mounted && !_cancelRequested) {
        setState(() => _error = _message(error));
      }
    }
  }

  Future<void> _loadPreview(File file, {required bool original}) async {
    if (_busy) return;
    final generation = ++_previewGeneration;
    setState(() {
      _initializingPreview = true;
      _error = null;
      _cancelRequested = false;
    });
    final oldPlayer = _player;
    final comparisonPosition = oldPlayer?.value.position ?? Duration.zero;
    oldPlayer?.removeListener(_onPlayerChanged);
    _player = null;
    await oldPlayer?.dispose();
    if (!mounted || _cancelRequested || generation != _previewGeneration) {
      return;
    }
    final player =
        widget.controllerFactory?.call(file) ??
        VideoPlayerController.file(file);
    try {
      await player.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || _cancelRequested || generation != _previewGeneration) {
        await player.dispose();
        return;
      }
      await player.setLooping(true);
      if (!mounted || _cancelRequested || generation != _previewGeneration) {
        await player.dispose();
        return;
      }
      await player.seekTo(
        comparisonPosition > player.value.duration
            ? player.value.duration
            : comparisonPosition,
      );
      if (!mounted || _cancelRequested || generation != _previewGeneration) {
        await player.dispose();
        return;
      }
      setState(() {
        _player = player;
        _showOriginal = original;
      });
      player.addListener(_onPlayerChanged);
      _onPlayerChanged();
    } catch (error) {
      await player.dispose();
      if (mounted && !_cancelRequested && generation == _previewGeneration) {
        setState(() => _error = 'videoPreviewUnavailable');
      }
    } finally {
      if (mounted && generation == _previewGeneration) {
        setState(() => _initializingPreview = false);
      }
    }
  }

  void _onPlayerChanged() {
    if (!mounted || _player?.value.hasError != true) return;
    if (_error != 'videoPlaybackUnavailable') {
      setState(() => _error = 'videoPlaybackUnavailable');
    }
  }

  Future<void> _cancel() async {
    if (_service.isSaving || _savingRequested || _cancelRequested) return;
    setState(() {
      _cancelRequested = true;
      _previewGeneration++;
      _initializingPreview = false;
    });
    try {
      await _service.cancel();
    } catch (_) {
      // The cancellation flag still prevents this page from using late output.
    }
  }

  Future<void> _save() async {
    if (_busy ||
        !context.read<SubscriptionManager>().isPro ||
        _showOriginal ||
        _player?.value.hasError == true ||
        _player?.value.isInitialized != true) {
      return;
    }
    setState(() {
      _error = null;
      _savingRequested = true;
    });
    try {
      await _player?.pause();
      if (!mounted ||
          !context.read<SubscriptionManager>().isPro ||
          _player?.value.hasError == true ||
          _player?.value.isInitialized != true) {
        return;
      }
      await _service.savePrepared();
      if (mounted) setState(() => _error = null);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _savingRequested = false);
    }
  }

  Future<void> _chooseAnotherPreset() async {
    if (_busy || _service.prepared == null || _service.savedAssetId != null) {
      return;
    }
    setState(() {
      _resettingPreset = true;
      _previewGeneration++;
      _error = null;
    });
    final player = _player;
    player?.removeListener(_onPlayerChanged);
    _player = null;
    try {
      await player?.dispose();
      if (!mounted) return;
      await _service.discardPrepared();
      if (mounted) setState(() => _showOriginal = false);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _resettingPreset = false);
    }
  }

  String _message(Object error) => error is StateError
      ? error.message.toString()
      : 'videoOperationIncomplete';

  String _localizedError(String source) => switch (source) {
    'videoPreviewUnavailable' => context.l10n.videoPreviewUnavailable,
    'videoPlaybackUnavailable' => context.l10n.videoPlaybackUnavailable,
    'videoOperationIncomplete' => context.l10n.videoOperationIncomplete,
    _ => context.localizeServiceMessage(source),
  };

  String _bytes(int bytes) {
    final locale = context.l10n.localeName;
    return bytes >= 1073741824
        ? context.l10n.videoSizeGb(
            NumberFormat('0.00', locale).format(bytes / 1073741824),
          )
        : context.l10n.videoSizeMb(
            NumberFormat('0.0', locale).format(bytes / 1048576),
          );
  }

  String _presetLabel(VideoCompressionPreset preset) => switch (preset) {
    VideoCompressionPreset.smaller => context.l10n.videoPresetSmaller,
    VideoCompressionPreset.balanced => context.l10n.videoPresetBalanced,
    VideoCompressionPreset.higherQuality =>
      context.l10n.videoPresetHigherQuality,
  };

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _service,
    builder: (context, _) {
      final prepared = _service.prepared;
      final saved = _service.savedAssetId != null;
      final isPro = context.watch<SubscriptionManager>().isPro;
      return PopScope(
        canPop: _canLeave,
        child: Scaffold(
          appBar: AppBar(title: Text(context.l10n.videoTitle)),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.videoDescription,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (!isPro) Text(context.l10n.videoProRequired),
                    if (_cancelRequested)
                      Text(context.l10n.serviceVideoCancelled),
                    if (_service.isBusy && !_cancelRequested) ...[
                      LinearProgressIndicator(
                        value: _service.isSaving ? null : _service.progress,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _service.isSaving
                            ? context.l10n.videoSaving
                            : context.l10n.videoCompressionProgress(
                                (100 * _service.progress).round(),
                              ),
                      ),
                      if (!_service.isSaving)
                        TextButton(
                          onPressed: _cancel,
                          child: Text(context.l10n.videoCancelCompression),
                        ),
                    ],
                    if (_initializingPreview) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(context.l10n.videoLoadingPreview),
                      TextButton(
                        onPressed: _cancel,
                        child: Text(context.l10n.scanCancel),
                      ),
                    ],
                    if (_resettingPreset) const LinearProgressIndicator(),
                    if (_error != null) ...[
                      Text(
                        _localizedError(_error!),
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (prepared == null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.videoPresetTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: VideoCompressionPreset.values.map((
                                preset,
                              ) {
                                return ChoiceChip(
                                  label: Text(_presetLabel(preset)),
                                  selected: _preset == preset,
                                  onSelected: _busy || !isPro
                                      ? null
                                      : (_) => setState(() => _preset = preset),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.videoPresetNotice,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (prepared == null && !_busy)
                      FilledButton.icon(
                        onPressed: isPro ? _prepare : null,
                        icon: const Icon(Icons.compress_rounded),
                        label: Text(context.l10n.videoCreatePreview),
                      ),
                    if (prepared != null) ...[
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          Text(
                            context.l10n.videoOriginalSize(
                              _bytes(prepared.originalBytes),
                            ),
                          ),
                          Text(
                            context.l10n.videoCopySize(
                              _bytes(prepared.outputBytes),
                            ),
                          ),
                          Text(
                            context.l10n.videoSizeDifference(
                              _bytes(prepared.savedBytes),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.videoStorageNotice,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_player?.value.isInitialized == true &&
                          _player?.value.hasError != true) ...[
                        SizedBox(
                          height: 280,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: _player!.value.aspectRatio,
                              child: VideoPlayer(_player!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        VideoPlaybackControls(
                          controller: _player!,
                          enabled: !_busy,
                          onError: () {
                            if (mounted) {
                              setState(
                                () => _error = 'videoPlaybackUnavailable',
                              );
                            }
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: _player!,
                          builder: (context, value, _) => OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () async {
                                    try {
                                      if (value.isPlaying) {
                                        await _player!.pause();
                                      } else {
                                        await _player!.play();
                                      }
                                    } catch (_) {
                                      if (mounted) {
                                        setState(
                                          () => _error =
                                              'videoPlaybackUnavailable',
                                        );
                                      }
                                    }
                                  },
                            icon: Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(
                              (_showOriginal
                                  ? (value.isPlaying
                                        ? context.l10n.videoPauseOriginal
                                        : context.l10n.videoPlayOriginal)
                                  : (value.isPlaying
                                        ? context.l10n.videoPauseCopy
                                        : context.l10n.videoPlayCopy)),
                            ),
                          ),
                        ),
                      ],
                      Wrap(
                        spacing: 12,
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _loadPreview(
                                    prepared.original,
                                    original: true,
                                  ),
                            child: Text(context.l10n.videoViewOriginal),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _loadPreview(
                                    prepared.output,
                                    original: false,
                                  ),
                            child: Text(context.l10n.videoViewCopy),
                          ),
                        ],
                      ),
                      if (!saved)
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _chooseAnotherPreset,
                          icon: const Icon(Icons.tune),
                          label: Text(context.l10n.videoTryAnotherPreset),
                        ),
                      const SizedBox(height: 16),
                      if (saved)
                        Text(context.l10n.videoSaved)
                      else
                        FilledButton.icon(
                          onPressed:
                              _busy ||
                                  !isPro ||
                                  _showOriginal ||
                                  _player?.value.hasError == true ||
                                  _player?.value.isInitialized != true
                              ? null
                              : _save,
                          icon: const Icon(Icons.save_alt),
                          label: Text(context.l10n.videoConfirmSave),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
