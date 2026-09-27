import 'package:cleanup_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

String playbackTime(Duration value) =>
    '${(value.inSeconds ~/ 60).toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

class VideoPlaybackControls extends StatelessWidget {
  const VideoPlaybackControls({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onError,
  });
  final VideoPlayerController controller;
  final bool enabled;
  final VoidCallback? onError;
  Future<void> _perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      onError?.call();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: controller,
    builder: (context, value, _) {
      final duration = value.duration.inMilliseconds.toDouble();
      final position = value.position.inMilliseconds.toDouble().clamp(
        0.0,
        duration > 0 ? duration : 1.0,
      );
      return Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: value.isPlaying
                    ? context.l10n.videoPauseOriginal
                    : context.l10n.videoPlayOriginal,
                onPressed: enabled && !value.hasError
                    ? () => _perform(
                        value.isPlaying ? controller.pause : controller.play,
                      )
                    : null,
                icon: Icon(
                  value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
              Expanded(
                child: Slider(
                  value: position,
                  max: duration > 0 ? duration : 1.0,
                  semanticFormatterCallback: (v) =>
                      playbackTime(Duration(milliseconds: v.round())),
                  onChanged: enabled && duration > 0 && !value.hasError
                      ? (v) => _perform(
                          () => controller.seekTo(
                            Duration(milliseconds: v.round()),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
          Text(
            '${playbackTime(value.position)} / ${playbackTime(value.duration)}',
          ),
        ],
      );
    },
  );
}
