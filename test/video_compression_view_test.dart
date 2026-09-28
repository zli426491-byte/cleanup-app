import 'dart:async';
import 'dart:io';

import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/subscription_manager.dart';
import 'package:cleanup_app/services/video_compression_service.dart';
import 'package:cleanup_app/views/components/video_compression_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

class _ProSubscription extends SubscriptionManager {
  bool enabled = true;
  @override
  bool get isPro => enabled;
}

class _Backend implements VideoCompressionBackend {
  _Backend(this.directory, this.original, this.encoded);
  final Directory directory;
  final File original;
  final File encoded;
  Completer<File>? loading;
  Completer<String>? saving;
  int saveCalls = 0;
  int cancels = 0;
  VideoCompressionPreset? lastPreset;

  @override
  Future<File> load(String assetId) async => loading?.future ?? original;
  @override
  Future<MediaInfo> inspect(File file) async =>
      MediaInfo(path: file.path, width: 640, height: 480, duration: 10000);
  Future<File?> encode(File file, void Function(double) onProgress) async =>
      encoded;
  @override
  Future<File?> encodeWithQuality(
    File file,
    VideoCompressionPreset preset,
    void Function(double) onProgress,
  ) {
    lastPreset = preset;
    return encode(file, onProgress);
  }

  @override
  Future<Directory> temporaryDirectory() async => directory;
  @override
  Future<String> save(File file) async {
    saveCalls++;
    return saving?.future ?? 'saved-copy';
  }

  @override
  Future<void> cancel() async => cancels++;
  @override
  Future<void> releaseEncoded(File file, File original) async {}
}

class _Player extends VideoPlayerController {
  _Player(super.file) : super.file();
  bool disposed = false;
  Completer<void>? pausing;
  Completer<void>? initializing;
  Completer<void>? looping;
  @override
  Future<void> initialize() async {
    await initializing?.future;
    value = const VideoPlayerValue(
      duration: Duration(seconds: 10),
      size: Size(640, 480),
      isInitialized: true,
    );
  }

  @override
  Future<void> setLooping(bool shouldLoop) async => looping?.future;
  @override
  Future<void> pause() async {
    await pausing?.future;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);
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
  late Directory directory;
  late File original;
  late File encoded;
  late _Backend backend;
  late VideoCompressionService service;
  late _ProSubscription subscription;
  late List<_Player> players;
  late List<Completer<void>?> initializationGates;
  late List<Completer<void>?> loopingGates;
  final asset = PhotoAsset(
    id: 'video',
    width: 640,
    height: 480,
    size: 1000,
    createDate: DateTime(2026),
    type: AssetType.video,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cleanup_video_view_');
    original = await File(
      '${directory.path}/original.mov',
    ).writeAsBytes(List.filled(1000, 1));
    encoded = await File(
      '${directory.path}/encoded.mp4',
    ).writeAsBytes(List.filled(400, 2));
    backend = _Backend(directory, original, encoded);
    service = VideoCompressionService(backend: backend);
    subscription = _ProSubscription();
    players = [];
    initializationGates = [];
    loopingGates = [];
  });

  tearDown(() async {
    service.dispose();
    subscription.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // Only remove files directly inside this test-created directory.
    for (final entry in directory.listSync().whereType<File>()) {
      if (await entry.exists()) {
        try {
          await entry.delete();
        } on FileSystemException {
          // The service may have finished its owned-preview cleanup first.
        }
      }
    }
    await directory.delete();
  });

  Future<void> mount(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SubscriptionManager>.value(
        value: subscription,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: locale == null
              ? null
              : AppLocalizations.localizationsDelegates,
          supportedLocales: locale == null
              ? const [Locale('en')]
              : AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoCompressionView(
                      asset: asset,
                      service: service,
                      controllerFactory: (file) {
                        final player = _Player(file);
                        player.initializing = initializationGates.isEmpty
                            ? null
                            : initializationGates.removeAt(0);
                        player.looping = loopingGates.isEmpty
                            ? null
                            : loopingGates.removeAt(0);
                        players.add(player);
                        return player;
                      },
                    ),
                  ),
                ),
                child: const Text('open video'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open video'));
    await tester.pumpAndSettle();
  }

  Future<void> loadPreparedPreview(WidgetTester tester) async {
    await tester.runAsync(() => service.prepare(asset.id));
    await mount(tester);
    await tester.tap(find.text('查看壓縮副本'));
    await tester.pumpAndSettle();
    expect(players.single.value.isInitialized, isTrue);
    await tester.scrollUntilVisible(find.text('確認副本並另存至照片'), 150);
    await tester.pumpAndSettle();
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, '確認副本並另存至照片'),
  );

  testWidgets('quality can be chosen before creating a preview', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('原片：0.0 MB'), findsNothing);
    await tester.tap(find.text('較高畫質'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '較高畫質'))
          .selected,
      isTrue,
    );
    expect(find.text('建立壓縮預覽'), findsOneWidget);
    expect(backend.lastPreset, isNull);
  });

  testWidgets('free users cannot start a quality preset or encode', (
    tester,
  ) async {
    subscription.enabled = false;
    await mount(tester);
    for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
      expect(chip.onSelected, isNull);
    }
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '建立壓縮預覽'))
          .onPressed,
      isNull,
    );
    expect(backend.lastPreset, isNull);
  });

  testWidgets('all 19 languages fit iPhone and iPad quality selection', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final width in [390.0, 768.0]) {
      tester.view.physicalSize = Size(width, width == 390 ? 844 : 1024);
      tester.view.devicePixelRatio = 1;
      for (final locale in AppLocalizations.supportedLocales.where(
        (locale) => locale.toString() != 'zh',
      )) {
        await tester.pumpWidget(const SizedBox.shrink());
        service = VideoCompressionService(backend: backend);
        await mount(tester, locale: locale);
        expect(
          find.text(lookupAppLocalizations(locale).videoPresetNotice),
          findsOneWidget,
          reason: '$locale at $width px',
        );
        expect(tester.takeException(), isNull, reason: '$locale at $width px');
      }
    }
  });

  testWidgets(
    'original and compressed previews preserve the comparison position',
    (tester) async {
      await loadPreparedPreview(tester);
      expect(find.text('試試其他畫質'), findsOneWidget);
      tester.widget<Slider>(find.byType(Slider)).onChanged!(6500);
      await tester.pump();
      expect(players.last.value.position, const Duration(milliseconds: 6500));
      await tester.ensureVisible(find.text('查看原片'));
      await tester.tap(find.text('查看原片'));
      await tester.pumpAndSettle();
      expect(players.last.value.position, const Duration(milliseconds: 6500));
      expect(saveButton(tester).onPressed, isNull);
      await tester.ensureVisible(find.text('查看壓縮副本'));
      await tester.tap(find.text('查看壓縮副本'));
      await tester.pumpAndSettle();
      expect(players.last.value.position, const Duration(milliseconds: 6500));
      expect(saveButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets(
    'cancel during pending source loading allows safe exit before late completion',
    (tester) async {
      backend.loading = Completer<File>();
      await mount(tester);
      await tester.tap(find.text('建立壓縮預覽'));
      await tester.pump();
      expect(service.isBusy, isTrue);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      await navigator.maybePop();
      await tester.pump();
      expect(find.byType(VideoCompressionView), findsOneWidget);
      await tester.tap(find.text('取消壓縮'));
      await tester.pump();
      expect(
        service.isBusy,
        isTrue,
        reason: 'Native work stays mutually exclusive until settled.',
      );
      expect(find.text('已取消壓縮。'), findsOneWidget);
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(VideoCompressionView), findsNothing);
      await tester.runAsync(() async {
        backend.loading!.complete(original);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();
      expect(service.prepared, isNull);
      expect(backend.saveCalls, 0);
      expect(backend.cancels, 0);
      expect(original.existsSync(), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late playback error immediately disables save and reload recovers',
    (tester) async {
      await loadPreparedPreview(tester);
      expect(saveButton(tester).onPressed, isNotNull);
      players.single.value = const VideoPlayerValue.erroneous(
        'native decode failure',
      );
      await tester.pump();
      expect(find.text('影片暫時無法播放，請重新載入預覽。'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);
      expect(backend.saveCalls, 0);
      await tester.tap(find.text('查看壓縮副本'));
      await tester.pumpAndSettle();
      expect(players.first.disposed, isTrue);
      expect(players.last.value.isInitialized, isTrue);
      expect(find.text('影片暫時無法播放，請重新載入預覽。'), findsNothing);
      expect(saveButton(tester).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('saving remains protected from leaving and cannot be cancelled', (
    tester,
  ) async {
    await loadPreparedPreview(tester);
    backend.saving = Completer<String>();
    await tester.ensureVisible(find.text('確認副本並另存至照片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認副本並另存至照片'));
    await tester.pump();
    expect(service.isSaving, isTrue);
    expect(find.text('取消壓縮'), findsNothing);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
    await tester.pump();
    expect(find.byType(VideoCompressionView), findsOneWidget);
    backend.saving!.complete('saved-copy');
    await tester.pumpAndSettle();
    expect(service.savedAssetId, 'saved-copy');
    expect(backend.saveCalls, 1);
    expect(original.existsSync(), isTrue);
    expect(find.text('副本已另存至照片，原片保留。返回首頁重新掃描後，可自行選擇是否刪除原片。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('playback error while pausing prevents the pending save', (
    tester,
  ) async {
    await loadPreparedPreview(tester);
    players.single.pausing = Completer<void>();
    await tester.ensureVisible(find.text('確認副本並另存至照片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認副本並另存至照片'));
    await tester.pump();
    players.single.value = const VideoPlayerValue.erroneous(
      'error during pause',
    );
    players.single.pausing!.complete();
    await tester.pumpAndSettle();
    expect(backend.saveCalls, 0);
    expect(service.savedAssetId, isNull);
    expect(saveButton(tester).onPressed, isNull);
    expect(find.text('影片暫時無法播放，請重新載入預覽。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'cancel pending player initialization permits exit and disposes late player',
    (tester) async {
      final initialization = Completer<void>();
      initializationGates.add(initialization);
      await tester.runAsync(() => service.prepare(asset.id));
      await mount(tester);
      await tester.tap(find.text('查看壓縮副本'));
      await tester.pump();
      expect(find.text('正在載入影片預覽…'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);
      await tester.tap(find.text('取消'));
      await tester.pump();
      expect(find.text('正在載入影片預覽…'), findsNothing);
      expect(find.text('已取消壓縮。'), findsOneWidget);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(VideoCompressionView), findsNothing);
      initialization.complete();
      await tester.pumpAndSettle();
      expect(players.single.disposed, isTrue);
      expect(backend.saveCalls, 0);
      expect(original.existsSync(), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancelled preview late completion cannot overwrite a pending reload',
    (tester) async {
      final first = Completer<void>();
      final second = Completer<void>();
      initializationGates.addAll([first, second]);
      await tester.runAsync(() => service.prepare(asset.id));
      await mount(tester);
      await tester.tap(find.text('查看壓縮副本'));
      await tester.pump();
      await tester.tap(find.text('取消'));
      await tester.pump();
      await tester.tap(find.text('查看壓縮副本'));
      await tester.pump();
      expect(find.text('已取消壓縮。'), findsNothing);
      first.complete();
      await tester.pump();
      expect(players.first.disposed, isTrue);
      expect(find.text('正在載入影片預覽…'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);
      second.complete();
      await tester.pumpAndSettle();
      expect(players.last.disposed, isFalse);
      expect(saveButton(tester).onPressed, isNotNull);
      expect(find.text('正在載入影片預覽…'), findsNothing);
      expect(backend.saveCalls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('cancellation while setting up looping rejects the late player', (
    tester,
  ) async {
    final looping = Completer<void>();
    loopingGates.add(looping);
    await tester.runAsync(() => service.prepare(asset.id));
    await mount(tester);
    await tester.tap(find.text('查看壓縮副本'));
    await tester.pump();
    expect(players.single.value.isInitialized, isTrue);
    await tester.tap(find.text('取消'));
    await tester.pump();
    looping.complete();
    await tester.pumpAndSettle();
    expect(players.single.disposed, isTrue);
    expect(saveButton(tester).onPressed, isNull);
    expect(find.text('壓縮副本：播放'), findsNothing);
    expect(backend.saveCalls, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
