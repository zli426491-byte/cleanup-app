import 'dart:io';

import 'package:flutter/material.dart';
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
      if (mounted) setState(() => _error = '預覽無法播放，請重試。原片已保留。');
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
      : '操作未完成，原片已保留。請檢查照片權限、可用空間後重試。';

  String _bytes(int bytes) => bytes >= 1073741824
      ? '${(bytes / 1073741824).toStringAsFixed(2)} GB'
      : '${(bytes / 1048576).toStringAsFixed(1)} MB';

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
          appBar: AppBar(title: const Text('影片壓縮')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    '壓縮會降低畫質並產生新副本。先檢查畫面、聲音與方向，再另存至照片。原片會保留。',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  if (!isPro) const Text('這項功能需要 Pro，請返回清理頁查看方案。'),
                  if (_service.isBusy) ...[
                    LinearProgressIndicator(
                      value: _service.isSaving ? null : _service.progress,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _service.isSaving
                          ? '正在另存至照片，請等待完成。'
                          : '正在準備／壓縮影片 ${(100 * _service.progress).round()}%',
                    ),
                    if (!_service.isSaving)
                      TextButton(
                        onPressed: () async {
                          try {
                            await _service.cancel();
                          } catch (_) {}
                        },
                        child: const Text('取消壓縮'),
                      ),
                  ],
                  if (_initializingPreview) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('正在載入影片預覽…'),
                  ],
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (prepared == null && !_busy)
                    FilledButton.icon(
                      onPressed: isPro ? _prepare : null,
                      icon: const Icon(Icons.compress_rounded),
                      label: const Text('建立壓縮預覽'),
                    ),
                  if (prepared != null) ...[
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        Text('原片：${_bytes(prepared.originalBytes)}'),
                        Text('副本：${_bytes(prepared.outputBytes)}'),
                        Text('檔案差額：${_bytes(prepared.savedBytes)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '另存副本會暫時增加用量。刪除原片及清空「最近刪除」後，裝置實際可用空間以系統為準。',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
                                        () => _error = '影片暫時無法播放，請重新載入預覽。',
                                      );
                                    }
                                  }
                                },
                          icon: Icon(
                            value.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(
                            '${_showOriginal ? "原片" : "壓縮副本"}：${value.isPlaying ? "暫停" : "播放"}',
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
                          child: const Text('查看原片'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _loadPreview(
                                  prepared.output,
                                  original: false,
                                ),
                          child: const Text('查看壓縮副本'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (saved)
                      const Text('副本已另存至照片，原片保留。返回首頁重新掃描後，可自行選擇是否刪除原片。')
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
                        label: const Text('確認副本並另存至照片'),
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
