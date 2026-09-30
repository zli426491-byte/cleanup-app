import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cleanup_app/services/video_compression_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:video_compress/video_compress.dart';

class FakeBackend implements VideoCompressionBackend {
  final Directory directory;
  final File original;
  final File encoded;
  bool sameFile = false;
  bool badDuration = false;
  bool saveFails = false;
  int saves = 0;
  int cancels = 0;
  Completer<File?>? encoding;
  Completer<File>? loading;
  final List<void Function(double)> progressCallbacks = [];
  int released = 0;
  VideoCompressionPreset? lastPreset;
  Completer<String>? saving;
  FakeBackend(this.directory, this.original, this.encoded);

  @override
  Future<File> load(String assetId) async =>
      loading != null ? loading!.future : original;
  @override
  Future<MediaInfo> inspect(File file) async => MediaInfo(
    path: file.path,
    width: 640,
    height: 480,
    duration: file.path != original.path && badDuration ? 500 : 10000,
  );
  Future<File?> encode(File file, void Function(double) onProgress) async {
    onProgress(0.5);
    progressCallbacks.add(onProgress);
    return encoding != null
        ? encoding!.future
        : sameFile
        ? original
        : encoded;
  }

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
    saves++;
    if (saveFails) throw StateError('Permission denied');
    expect(await file.exists(), isTrue);
    return saving != null ? saving!.future : 'new-copy';
  }

  @override
  Future<void> cancel() async => cancels++;
  @override
  Future<void> releaseEncoded(File file, File original) async {
    released++;
  }
}

class TestDeviceBackend extends DeviceVideoCompressionBackend {
  final Directory cache;
  TestDeviceBackend(this.cache) : super(isIos: true);
  @override
  Future<Directory> temporaryDirectory() async => cache;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File original;
  late File encoded;
  late FakeBackend backend;
  late VideoCompressionService service;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'cleanup_compression_test_',
    );
    original = await File(
      '${directory.path}/original.mov',
    ).writeAsBytes(List.filled(10000, 7));
    encoded = await File(
      '${directory.path}/encoder.mp4',
    ).writeAsBytes(List.filled(4000, 9));
    backend = FakeBackend(directory, original, encoded);
    service = VideoCompressionService(backend: backend);
  });

  tearDown(() async {
    service.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // Only files in the test-created directory are removed; never recurse.
    for (final entity in directory.listSync()) {
      if (entity is File &&
          entity.parent.absolute.path == directory.absolute.path) {
        if (await entity.exists()) await entity.delete();
      } else if (entity is Directory &&
          entity.parent.absolute.path == directory.absolute.path) {
        for (final child
            in entity.listSync(followLinks: false).whereType<File>()) {
          if (child.parent.absolute.path == entity.absolute.path) {
            await child.delete();
          }
        }
        await entity.delete();
      }
    }
    await directory.delete();
  });

  test(
    'creates an owned preview and never writes or deletes the original',
    () async {
      final result = await service.prepare('source');
      expect(result.output.path, isNot(encoded.path));
      expect(result.originalBytes, 10000);
      expect(result.outputBytes, 4000);
      expect(result.savedBytes, 6000);
      expect(backend.lastPreset, VideoCompressionPreset.balanced);
      expect(await original.readAsBytes(), everyElement(7));
      expect(backend.saves, 0);
      expect(await service.savePrepared(), 'new-copy');
      expect(await service.savePrepared(), 'new-copy');
      await expectLater(service.discardPrepared(), throwsStateError);
      expect(
        backend.saves,
        1,
        reason: 'Repeated save must not create another gallery copy.',
      );
      expect(await original.exists(), isTrue);
    },
  );

  test(
    'passes the selected native quality without estimating output size',
    () async {
      expect(
        VideoCompressionPreset.smaller.videoQuality,
        VideoQuality.LowQuality,
      );
      expect(
        VideoCompressionPreset.balanced.videoQuality,
        VideoQuality.MediumQuality,
      );
      expect(
        VideoCompressionPreset.higherQuality.videoQuality,
        VideoQuality.HighestQuality,
      );
      final result = await service.prepare(
        'source',
        preset: VideoCompressionPreset.higherQuality,
      );
      expect(backend.lastPreset, VideoCompressionPreset.higherQuality);
      expect(result.outputBytes, 4000);
      expect(await original.readAsBytes(), everyElement(7));
    },
  );

  test('trying another preset deletes only the temporary preview', () async {
    final first = await service.prepare(
      'source',
      preset: VideoCompressionPreset.higherQuality,
    );
    expect(await first.output.exists(), isTrue);
    await service.discardPrepared();
    expect(await first.output.exists(), isFalse);
    expect(service.prepared, isNull);
    expect(await original.readAsBytes(), everyElement(7));
    final second = await service.prepare(
      'source',
      preset: VideoCompressionPreset.smaller,
    );
    expect(backend.lastPreset, VideoCompressionPreset.smaller);
    expect(await second.output.exists(), isTrue);
    expect(await original.readAsBytes(), everyElement(7));
  });

  test('rejects an encoder returning the source path', () async {
    backend.sameFile = true;
    await expectLater(service.prepare('source'), throwsStateError);
    expect(await original.length(), 10000);
    expect(service.prepared, isNull);
  });

  test(
    'rejects an empty output and an output larger than the source',
    () async {
      await encoded.writeAsBytes([]);
      await expectLater(service.prepare('source'), throwsStateError);
      await encoded.writeAsBytes(List.filled(11000, 9));
      await expectLater(service.prepare('source'), throwsStateError);
      expect(
        directory.listSync().where(
          (file) => file.path.contains('cleanup_preview_'),
        ),
        isEmpty,
      );
      expect(await original.length(), 10000);
    },
  );

  test('duration mismatch removes only the owned preview', () async {
    backend.badDuration = true;
    await expectLater(service.prepare('source'), throwsStateError);
    expect(
      directory.listSync().where(
        (file) => file.path.contains('cleanup_preview_'),
      ),
      isEmpty,
    );
    expect(await original.exists(), isTrue);
    expect(await encoded.exists(), isTrue);
  });

  test('cancellation rejects late encoding and cannot save it', () async {
    backend.encoding = Completer<File?>();
    final operation = service.prepare('source');
    final expectation = expectLater(operation, throwsStateError);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.cancel();
    expect(
      service.isBusy,
      isTrue,
      reason: 'Native operation has not settled yet.',
    );
    backend.encoding!.complete(encoded);
    await expectation;
    expect(service.prepared, isNull);
    await expectLater(service.savePrepared(), throwsStateError);
    expect(backend.saves, 0);
    expect(await original.exists(), isTrue);
    expect(
      backend.cancels,
      1,
      reason: 'Do not poison the next iOS export with a second cancel.',
    );
  });

  test(
    'cancellation while loading does not cancel an idle native encoder',
    () async {
      backend.loading = Completer<File>();
      final operation = service.prepare('source');
      final expectation = expectLater(operation, throwsStateError);
      await service.cancel();
      backend.loading!.complete(original);
      await expectation;
      expect(backend.cancels, 0);
      expect(backend.progressCallbacks, isEmpty);
    },
  );

  test('old progress and output after timeout cannot affect a retry', () async {
    service.dispose();
    service = VideoCompressionService(
      backend: backend,
      encodingTimeout: const Duration(milliseconds: 40),
    );
    final first = Completer<File?>();
    backend.encoding = first;
    await expectLater(
      service.prepare('source'),
      throwsA(isA<TimeoutException>()),
    );
    expect(backend.cancels, 1);
    final second = Completer<File?>();
    backend.encoding = second;
    final retry = service.prepare('source');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final current = service.progress;
    backend.progressCallbacks.first(0.99);
    expect(service.progress, current);
    first.complete(encoded);
    await Future<void>.delayed(Duration.zero);
    expect(backend.released, greaterThan(0));
    second.complete(encoded);
    await retry;
  });

  test(
    'saving failure preserves a retryable preview and the original',
    () async {
      final result = await service.prepare('source');
      backend.saveFails = true;
      await expectLater(service.savePrepared(), throwsStateError);
      expect(service.savedAssetId, isNull);
      expect(await result.output.exists(), isTrue);
      expect(await original.exists(), isTrue);
      backend.saveFails = false;
      expect(await service.savePrepared(), 'new-copy');
    },
  );

  test('native saving cannot overlap another save or cancellation', () async {
    await service.prepare('source');
    backend.saving = Completer<String>();
    final save = service.savePrepared();
    await expectLater(service.savePrepared(), throwsStateError);
    await service.cancel();
    expect(backend.cancels, 0);
    backend.saving!.complete('saved');
    expect(await save, 'saved');
    expect(backend.saves, 1);
  });

  test('a second preparation cannot overlap the encoder', () async {
    backend.encoding = Completer<File?>();
    final operation = service.prepare('source');
    await expectLater(service.prepare('other'), throwsStateError);
    backend.encoding!.complete(encoded);
    await operation;
  });

  test(
    'native output cleanup preserves old cache files and the source',
    () async {
      const media = MethodChannel('cleanup/photo_resources');
      const encoder = MethodChannel('video_compress');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final plugin = await Directory(
        '${directory.path}/video_compress',
      ).create();
      final oldCache = await File(
        '${plugin.path}/old.mp4',
      ).writeAsBytes([1, 2]);
      final fresh = File('${plugin.path}/new.mp4');
      messenger.setMockMethodCallHandler(media, (call) async => plugin.path);
      messenger.setMockMethodCallHandler(encoder, (call) async {
        expect(call.method, 'compressVideo');
        expect((call.arguments as Map)['deleteOrigin'], isFalse);
        expect((call.arguments as Map)['includeAudio'], isTrue);
        expect(
          (call.arguments as Map)['quality'],
          VideoQuality.LowQuality.index,
        );
        await fresh.writeAsBytes(List.filled(1000, 8));
        return jsonEncode({'path': fresh.path, 'isCancel': false});
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(media, null);
        messenger.setMockMethodCallHandler(encoder, null);
      });
      final device = TestDeviceBackend(directory);
      final result = await device.encodeWithQuality(
        original,
        VideoCompressionPreset.smaller,
        (_) {},
      );
      expect(result, isNotNull);
      expect(await fresh.exists(), isFalse);
      expect(await oldCache.exists(), isTrue);
      expect(await original.length(), 10000);
      expect(await result!.length(), 1000);
      await device.releaseEncoded(result, original);
      expect(await result.exists(), isFalse);
    },
  );

  test(
    'native cancellation during setup never poisons an idle encoder',
    () async {
      const media = MethodChannel('cleanup/photo_resources');
      const encoder = MethodChannel('video_compress');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final rootReply = Completer<String>();
      var nativeCalls = 0;
      messenger.setMockMethodCallHandler(
        media,
        (call) async => rootReply.future,
      );
      messenger.setMockMethodCallHandler(encoder, (call) async {
        nativeCalls++;
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(media, null);
        messenger.setMockMethodCallHandler(encoder, null);
      });
      final device = TestDeviceBackend(directory);
      final operation = device.encode(original, (_) {});
      await Future<void>.delayed(Duration.zero);
      await device.cancel();
      rootReply.complete('${directory.path}/video_compress');
      expect(await operation, isNull);
      expect(nativeCalls, 0);
    },
  );
}
