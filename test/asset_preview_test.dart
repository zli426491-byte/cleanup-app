import 'dart:async';
import 'dart:io';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/views/scanner/asset_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class PreviewPlayer extends VideoPlayerController {
  PreviewPlayer(super.file) : super.file();
  Completer<void>? initialization;
  bool disposed = false;
  @override
  Future<void> initialize() async {
    await initialization?.future;
    value = const VideoPlayerValue(
      duration: Duration(seconds: 80),
      size: Size(640, 480),
      isInitialized: true,
    );
  }

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);
  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);
  @override
  Future<void> seekTo(Duration position) async =>
      value = value.copyWith(position: position);
  @override
  Future<void> dispose() async {
    disposed = true;
    await super.dispose();
  }
}

void main() {
  final asset = PhotoAsset(
    id: 'original-preview',
    width: 640,
    height: 480,
    size: 0,
    createDate: DateTime(2026),
    type: AssetType.video,
  );
  testWidgets(
    'original video plays and seeks without a subscription or compression',
    (tester) async {
      final player = PreviewPlayer(File('local-original.mov'));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssetPreviewContent(
              asset: asset,
              videoFileLoader: (_) async => File('local-original.mov'),
              controllerFactory: (_) => player,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(find.text('00:00 / 01:20'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(player.value.isPlaying, isTrue);
      tester.widget<Slider>(find.byType(Slider)).onChanged!(45000);
      await tester.pump();
      expect(player.value.position, const Duration(seconds: 45));
      expect(find.text('00:45 / 01:20'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(player.disposed, isTrue);
    },
  );
  testWidgets('leaving while original initializes disposes the late player', (
    tester,
  ) async {
    final gate = Completer<void>();
    final player = PreviewPlayer(File('local.mov'))..initialization = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetPreviewContent(
            asset: asset,
            videoFileLoader: (_) async => File('local.mov'),
            controllerFactory: (_) => player,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pump();
    expect(player.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unavailable original has retry and recovers without leaving', (
    tester,
  ) async {
    var attempts = 0;
    final player = PreviewPlayer(File('local.mov'));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetPreviewContent(
            asset: asset,
            videoFileLoader: (_) async {
              if (++attempts == 1) throw StateError('cloud');
              return File('local.mov');
            },
            controllerFactory: (_) => player,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VideoPlayer), findsNothing);
    await tester.tap(find.byTooltip('重新載入預覽'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(VideoPlayer), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
