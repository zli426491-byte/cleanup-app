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

class VideoCompressionView extends StatefulWidget {
  final PhotoAsset asset;
  const VideoCompressionView({super.key, required this.asset});

  @override
  State<VideoCompressionView> createState() => _VideoCompressionViewState();
}

class _VideoCompressionViewState extends State<VideoCompressionView> {
  final _service = VideoCompressionService();
  VideoPlayerController? _player;
  bool _initializingPreview = false;
  bool _savingRequested = false;
  bool _showOriginal = false;
  String? _error;

  bool get _busy => _service.isBusy || _initializingPreview || _savingRequested;

  @override
  void dispose() {
    _player?.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    if (_busy || !context.read<SubscriptionManager>().isPro) return;
    setState(() => _error = null);
    try {
      final prepared = await _service.prepare(widget.asset.id);
      if (!mounted) return;
      await _loadPreview(prepared.output, original: false);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  Future<void> _loadPreview(File file, {required bool original}) async {
    if (_busy) return;
    setState(() {
      _initializingPreview = true;
      _error = null;
    });
    final oldPlayer = _player;
    _player = null;
    await oldPlayer?.dispose();
    if (!mounted) return;
    final player = VideoPlayerController.file(file);
    try {
      await player.initialize().timeout(const Duration(seconds: 30));
      if (!mounted) {
        await player.dispose();
        return;
      }
      await player.setLooping(true);
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _player = player;
        _showOriginal = original;
      });
    } catch (error) {
      await player.dispose();
      if (mounted) setState(() => _error = 'videoPreviewUnavailable');
    } finally {
      if (mounted) setState(() => _initializingPreview = false);
    }
  }

  Future<void> _save() async {
    if (_busy ||
        !context.read<SubscriptionManager>().isPro ||
        _showOriginal ||
        _player?.value.isInitialized != true) {
      return;
    }
    setState(() {
      _error = null;
      _savingRequested = true;
    });
    try {
      await _player?.pause();
      if (!mounted || !context.read<SubscriptionManager>().isPro) return;
      await _service.savePrepared();
      if (mounted) setState(() => _error = null);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _savingRequested = false);
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _service,
    builder: (context, _) {
      final prepared = _service.prepared;
      final saved = _service.savedAssetId != null;
      final isPro = context.watch<SubscriptionManager>().isPro;
      return PopScope(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(title: Text(context.l10n.videoTitle)),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    context.l10n.videoDescription,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  if (!isPro) Text(context.l10n.videoProRequired),
                  if (_service.isBusy) ...[
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
                        onPressed: () async {
                          try {
                            await _service.cancel();
                          } catch (_) {}
                        },
                        child: Text(context.l10n.videoCancelCompression),
                      ),
                  ],
                  if (_initializingPreview) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(context.l10n.videoLoadingPreview),
                  ],
                  if (_error != null) ...[
                    Text(
                      _localizedError(_error!),
                      style: const TextStyle(color: AppTheme.danger),
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
                    if (_player?.value.isInitialized == true) ...[
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
                                        () =>
                                            _error = 'videoPlaybackUnavailable',
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
                    const SizedBox(height: 16),
                    if (saved)
                      Text(context.l10n.videoSaved)
                    else
                      FilledButton.icon(
                        onPressed:
                            _busy ||
                                !isPro ||
                                _showOriginal ||
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
      );
    },
  );
}
