import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:cleanup_app/services/photo_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluttercandies/photo_manager');
  const resources = MethodChannel('cleanup/photo_resources');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late PhotoScannerService scanner;
  late List<Map<String, Object>> library;
  late List<String> deletedBySystem;
  late List<List<String>> deletionRequests;
  late PermissionState permission;
  late List<int> rangeEnds;
  Completer<int>? permissionResponse;
  Completer<List<String>>? deletionResponse;
  Completer<Map<String, Object>>? resourceResponse;
  Completer<Map<String, Object>>? pageResponse;
  late Map<String, Map<String, Object>> nativeResults;
  late List<String> resourceRequests;
  late List<Map> resourceArguments;
  Future<Map<String, Object>> Function(String)? resourceHandler;
  late List<List<String>> previewRequests;
  Completer<Map<String, Object>>? previewResponse;
  Future<Map<String, Object>> Function(List<String>)? previewHandler;
  late List<Map> nativeCancellations;

  Map<String, Object> photo(
    String id, {
    int type = 1,
    int created = 1700000000,
  }) => {
    'id': id,
    'type': type,
    'width': 3000,
    'height': 2000,
    'createDt': created,
    'modifiedDt': created,
    'title': 'same-name.jpg',
  };

  Uint8List preview({bool alternate = false}) {
    final image = img.Image(width: 96, height: 64);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final value = alternate
            ? (x < 48 ? 35 : 230)
            : ((x ~/ 12 + y ~/ 8).isEven ? 60 : 220);
        image.setPixelRgb(
          x,
          y,
          value,
          alternate ? y * 3 : value,
          alternate ? 180 : x * 2,
        );
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  Map<String, Object> inspected(
    String content, {
    int size = 234567,
    Uint8List? thumbnail,
  }) => {
    'sizeKnown': true,
    'size': size,
    'complete': true,
    'hash': sha256.convert(utf8.encode(content)).toString(),
    'thumbnail': thumbnail ?? preview(),
  };

  setUp(() {
    scanner = PhotoScannerService(supportsNativeResources: true);
    library = [photo('first'), photo('second')];
    deletedBySystem = [];
    deletionRequests = [];
    rangeEnds = [];
    permission = PermissionState.authorized;
    permissionResponse = null;
    deletionResponse = null;
    resourceResponse = null;
    pageResponse = null;
    nativeResults = {};
    resourceRequests = [];
    resourceArguments = [];
    resourceHandler = null;
    previewRequests = [];
    previewResponse = null;
    previewHandler = null;
    nativeCancellations = [];
    messenger.setMockMethodCallHandler(resources, (call) async {
      final args = call.arguments as Map;
      if (call.method == 'cancelInspections') {
        nativeCancellations.add(args);
        return null;
      }
      if (call.method == 'inspectPreviews') {
        final ids = List<String>.from(args['assetIds'] as List);
        previewRequests.add(ids);
        if (previewResponse != null) return previewResponse!.future;
        if (previewHandler != null) return previewHandler!(ids);
        return {
          'assets': ids
              .map(
                (id) => {
                  'assetId': id,
                  'status': nativeResults[id]?['thumbnail'] != null
                      ? 'local'
                      : 'not_local',
                  if (nativeResults[id]?['thumbnail'] != null)
                    'thumbnail': nativeResults[id]!['thumbnail']!,
                  if (nativeResults[id]?['thumbnailDegraded'] != null)
                    'thumbnailDegraded':
                        nativeResults[id]!['thumbnailDegraded']!,
                },
              )
              .toList(),
        };
      }
      expectSync(call.method, 'inspectAsset');
      expectSync(args['includeThumbnail'], false);
      expectSync(args['resourceTimeoutMs'], 4000);
      expectSync(args['maxBytes'], 64 * 1024 * 1024);
      final id = args['assetId'] as String;
      resourceRequests.add(id);
      resourceArguments.add(Map.of(args));
      if (resourceResponse != null) return resourceResponse!.future;
      if (resourceHandler != null) return resourceHandler!(id);
      return nativeResults[id] ??
          {
            'sizeKnown': false,
            'size': 0,
            'complete': false,
            'pendingReason': 'local_resource_unavailable',
          };
    });
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'requestPermissionExtend':
          return permissionResponse == null
              ? permission.index
              : permissionResponse!.future;
        case 'getAssetPathList':
          return {
            'data': [
              {
                'id': 'all',
                'name': 'All',
                'isAll': true,
                'assetCount': library.length,
              },
            ],
          };
        case 'getAssetCountFromPath':
          return library.length;
        case 'getAssetListRange':
          final args = call.arguments as Map;
          final start = args['start'] as int;
          final end = args['end'] as int;
          rangeEnds.add(end);
          return pageResponse == null
              ? {'data': library.sublist(start, end)}
              : pageResponse!.future;
        case 'deleteWithIds':
          deletionRequests.add(
            List<String>.from((call.arguments as Map)['ids'] as List),
          );
          return deletionResponse == null
              ? deletedBySystem
              : deletionResponse!.future;
        default:
          throw StateError('Unexpected photo API ${call.method}');
      }
    });
  });

  tearDown(() {
    scanner.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(resources, null);
  });

  test('matching metadata alone produces no content group', () async {
    await scanner.startFullScan();
    expect(scanner.scanResult.duplicateGroups, isEmpty);
    expect(scanner.scanResult.similarGroups, isEmpty);
    expect(scanner.scanResult.totalSavingsEstimate, 0);
    expect(scanner.hasCompletedScan, isTrue);
  });

  test(
    'all accessible assets in a library over 5000 are paged without a cap',
    () async {
      library = List.generate(5007, (index) => photo('asset-$index'));
      await scanner.startFullScan();
      expect(scanner.scanResult.allAssets, hasLength(5007));
      expect(scanner.availableAssetCount, 5007);
      expect(rangeEnds.last, 5007);
      expect(scanner.scannedAssetCount, 5007);
      expect(previewRequests.expand((ids) => ids), hasLength(5007));
      expect(resourceRequests, isEmpty);
      expect(scanner.pendingAnalysisCount, 5007);
    },
  );

  test(
    'limited photo access indexes allowed assets and explains its scope',
    () async {
      permission = PermissionState.limited;
      await scanner.startFullScan();
      expect(scanner.scanResult.allAssets, hasLength(2));
      expect(scanner.scanNotice, contains('未讀取整個相簿'));
      expect(scanner.lastError, isNull);
    },
  );

  test(
    'denied access is explained instead of claiming a clean album',
    () async {
      permission = PermissionState.denied;
      await scanner.startFullScan();
      expect(scanner.scanResult.allAssets, isEmpty);
      expect(scanner.lastError, contains('相簿權限'));
      expect(rangeEnds, isEmpty);
    },
  );

  test('video dimensions do not classify a video as a large file', () async {
    library = [photo('video', type: 2)];
    await scanner.startFullScan();
    expect(scanner.scanResult.videos, hasLength(1));
    expect(scanner.scanResult.largeFiles, isEmpty);
  });

  test('cancelled native deletion preserves every indexed asset', () async {
    await scanner.startFullScan();
    final deleted = await scanner.deleteAssetsWithResult(
      scanner.scanResult.allAssets,
    );
    expect(deleted, isEmpty);
    expect(scanner.scanResult.allAssets, hasLength(2));
    expect(scanner.scanResult.similarGroups, isEmpty);
    expect(scanner.availableAssetCount, 2);
  });

  test('partial deletion removes only confirmed requested IDs', () async {
    await scanner.startFullScan();
    deletedBySystem = ['first', 'unrequested-id'];
    final deleted = await scanner.deleteAssetsWithResult(
      scanner.scanResult.allAssets,
    );
    expect(deleted, {'first'});
    expect(scanner.scanResult.allAssets.single.id, 'second');
    expect(scanner.scanResult.similarGroups, isEmpty);
    expect(scanner.availableAssetCount, 1);
  });

  test('empty deletion never invokes the device editor', () async {
    expect(await scanner.deleteAssetsWithResult([]), isEmpty);
    expect(deletionRequests, isEmpty);
  });

  test(
    'original resource fingerprints group exact content across different identifiers and names',
    () async {
      library = [
        photo('first'),
        {...photo('second', created: 1800000000), 'title': 'renamed.heic'},
      ];
      nativeResults = {
        'first': inspected('same-all-resource-content'),
        'second': inspected('same-all-resource-content'),
      };
      await scanner.startFullScan();
      await scanner.verifyOriginals();
      final group = scanner.scanResult.duplicateGroups.single;
      expect(
        group.assets.map((asset) => asset.id),
        containsAll(['first', 'second']),
      );
      expect(
        group.assets.map((asset) => asset.id),
        contains(group.bestAssetId),
      );
      expect(group.bestReason, isNotEmpty);
      expect(scanner.scanResult.similarGroups, isEmpty);
      expect(scanner.analyzedAssetCount, 2);
    },
  );

  test(
    'same metadata with different originals cannot be an exact duplicate',
    () async {
      nativeResults = {
        'first': inspected('original-A'),
        'second': inspected('original-B', thumbnail: preview(alternate: true)),
      };
      await scanner.startFullScan();
      await scanner.verifyOriginals();
      expect(scanner.scanResult.duplicateGroups, isEmpty);
      expect(scanner.scanResult.similarGroups, isEmpty);
    },
  );

  test('visual candidates have a reversible keep recommendation', () async {
    nativeResults = {
      'first': inspected('original-A'),
      'second': inspected('original-B'),
    };
    await scanner.startFullScan();
    expect(scanner.scanResult.duplicateGroups, isEmpty);
    final group = scanner.scanResult.similarGroups.single;
    expect(group.assets.map((asset) => asset.id), contains(group.bestAssetId));
    expect(group.bestReason, isNotEmpty);
  });

  test(
    'unknown or partially read resource sizes stay unknown and cannot form duplicates',
    () async {
      nativeResults = {
        'first': {...inspected('same'), 'complete': false},
        'second': {...inspected('same'), 'sizeKnown': false},
      };
      await scanner.startFullScan();
      await scanner.verifyOriginals();
      expect(
        scanner.scanResult.allAssets.every(
          (asset) => !asset.sizeKnown && asset.size == 0 && asset.hash == null,
        ),
        isTrue,
      );
      expect(scanner.pendingAnalysisCount, 0);
      expect(scanner.pendingResourceCount, 2);
      expect(scanner.scanResult.duplicateGroups, isEmpty);
      expect(scanner.scanResult.similarGroups, hasLength(1));
      expect(scanner.scanResult.largeFiles, isEmpty);
    },
  );

  test(
    'large file classification uses measured bytes including videos',
    () async {
      library = [photo('video', type: 2), photo('first')];
      nativeResults = {
        'video': inspected('video', size: 9000000),
        'first': inspected('image', size: 900000),
      };
      await scanner.startFullScan();
      await scanner.verifyOriginals();
      expect(scanner.scanResult.largeFiles.single.id, 'video');
      expect(
        scanner.scanResult.allAssets
            .firstWhere((asset) => asset.id == 'video')
            .size,
        9000000,
      );
    },
  );

  test(
    'cancelled page reads preserve current results and reject a late page before resume',
    () async {
      library = List.generate(250, (index) => photo('asset-$index'));
      var firstPagePublished = false;
      scanner.addListener(() {
        if (!firstPagePublished && scanner.scannedAssetCount == 120) {
          firstPagePublished = true;
          pageResponse = Completer<Map<String, Object>>();
        }
      });
      final scan = scanner.startFullScan();
      while (rangeEnds.length < 2) {
        await Future<void>.delayed(Duration.zero);
      }
      scanner.cancelScan();
      await scan;
      expect(scanner.scannedAssetCount, 120);
      expect(scanner.wasCancelled, isTrue);
      final latePage = pageResponse!;
      pageResponse = null;
      await scanner.resumeScan();
      expect(scanner.scannedAssetCount, 250);
      latePage.complete({
        'data': [photo('late-obsolete')],
      });
      await Future<void>.delayed(Duration.zero);
      expect(
        scanner.scanResult.allAssets.map((asset) => asset.id),
        isNot(contains('late-obsolete')),
      );
    },
  );

  test(
    'native analysis cancelled before a new run cannot overwrite its result',
    () async {
      resourceResponse = Completer<Map<String, Object>>();
      await scanner.startFullScan();
      final scan = scanner.verifyOriginals();
      while (resourceRequests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      scanner.cancelScan();
      await scan;
      expect(
        scanner.scanResult.allAssets.every((asset) => !asset.sizeKnown),
        isTrue,
      );
      final oldResponse = resourceResponse!;
      resourceResponse = null;
      nativeResults = {
        'first': inspected('new-first', size: 333),
        'second': inspected('new-second', size: 444),
      };
      await scanner.resumeScan();
      await scanner.verifyOriginals();
      oldResponse.complete(inspected('old-late', size: 9999999));
      await Future<void>.delayed(Duration.zero);
      expect(
        scanner.scanResult.allAssets
            .firstWhere((asset) => asset.id == 'first')
            .size,
        333,
      );
      expect(nativeCancellations, isNotEmpty);
    },
  );

  test(
    'resume refreshes a changed limited-access set even when its count stays equal',
    () async {
      permission = PermissionState.limited;
      await scanner.startFullScan();
      library = [photo('third'), photo('fourth')];
      await scanner.resumeScan();
      expect(
        scanner.scanResult.allAssets.map((asset) => asset.id),
        containsAll(['third', 'fourth']),
      );
      expect(
        scanner.scanResult.allAssets.map((asset) => asset.id),
        isNot(contains('first')),
      );
    },
  );

  test(
    'resume preserves unchanged analyses but invalidates same-ID edits',
    () async {
      nativeResults = {
        'first': inspected('first'),
        'second': inspected('second'),
      };
      await scanner.startFullScan();
      await scanner.verifyOriginals();
      resourceRequests.clear();
      library = [
        {...photo('first'), 'modifiedDt': 1900000000},
        photo('second'),
      ];
      nativeResults['first'] = inspected('edited-first');
      await scanner.resumeScan();
      await scanner.verifyOriginals();
      expect(resourceRequests, ['first']);
      expect(
        scanner.scanResult.allAssets
            .firstWhere((asset) => asset.id == 'first')
            .hash,
        nativeResults['first']!['hash'],
      );
    },
  );

  test(
    'disposing during native analysis prevents late updates and cancels requests',
    () async {
      final subject = PhotoScannerService(supportsNativeResources: true);
      resourceResponse = Completer<Map<String, Object>>();
      await subject.startFullScan();
      final scan = subject.verifyOriginals();
      while (resourceRequests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      var updates = 0;
      subject.addListener(() => updates++);
      subject.dispose();
      await scan;
      resourceResponse!.complete(inspected('disposed-late'));
      await Future<void>.delayed(Duration.zero);
      expect(updates, 0);
      expect(nativeCancellations, isNotEmpty);
    },
  );

  test(
    'native deletion cannot overlap a scan and resurrect deleted results',
    () async {
      await scanner.startFullScan();
      final first = scanner.scanResult.allAssets.first;
      deletedBySystem = [first.id];
      Future<Set<String>>? deletion;
      var requested = false;
      scanner.addListener(() {
        if (scanner.isScanning && scanner.scanProgress >= 0.70 && !requested) {
          requested = true;
          deletion = scanner.deleteAssetsWithResult([first]);
        }
      });
      await scanner.startFullScan();
      final deleted = await deletion!;
      if (deleted.isNotEmpty) {
        expect(
          scanner.scanResult.allAssets.map((asset) => asset.id),
          isNot(contains(first.id)),
          reason:
              'A completed scan must not reinstall an asset already deleted by the OS.',
        );
      }
      expect(deletionRequests, isEmpty);
    },
  );

  test('a rescan cannot overlap a pending native deletion', () async {
    await scanner.startFullScan();
    final priorPageCalls = rangeEnds.length;
    deletionResponse = Completer<List<String>>();
    final deletion = scanner.deleteAssetsWithResult([
      scanner.scanResult.allAssets.first,
    ]);
    await Future<void>.delayed(Duration.zero);
    await scanner.startFullScan();
    deletionResponse!.complete(['first']);
    await deletion;
    expect(rangeEnds.length, priorPageCalls);
    expect(
      scanner.scanResult.allAssets.map((asset) => asset.id),
      isNot(contains('first')),
    );
  });

  test(
    'native deletion completion after disposal returns confirmed IDs without notifications',
    () async {
      final subject = PhotoScannerService(supportsNativeResources: true);
      await subject.startFullScan();
      deletionResponse = Completer<List<String>>();
      var notifications = 0;
      subject.addListener(() => notifications++);
      final deletion = subject.deleteAssetsWithResult([
        subject.scanResult.allAssets.first,
      ]);
      await Future<void>.delayed(Duration.zero);
      subject.dispose();
      deletionResponse!.complete(['first']);
      expect(await deletion, {'first'});
      expect(notifications, 1);
    },
  );

  testWidgets(
    'permission confirmation can wait longer than the scan watchdog',
    (tester) async {
      permissionResponse = Completer<int>();
      final scan = scanner.startFullScan();
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      expect(scanner.isScanning, isTrue);
      expect(scanner.hasCompletedScan, isFalse);
      expect(scanner.lastError, isNull);
      permissionResponse!.complete(PermissionState.authorized.index);
      for (var frame = 0; frame < 30 && scanner.isScanning; frame++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(scanner.isScanning, isFalse);
      await scan;
      expect(scanner.scanResult.allAssets, hasLength(2));
      expect(scanner.lastError, isNull);
    },
  );

  testWidgets(
    'explicit original verification times out promptly and ignores late streams',
    (tester) async {
      library = [photo('video', type: 2)];
      final indexed = scanner.startFullScan();
      for (var frame = 0; frame < 30 && scanner.isScanning; frame++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await indexed;
      expect(resourceRequests, isEmpty);
      resourceResponse = Completer<Map<String, Object>>();
      final verification = scanner.verifyOriginals();
      for (var frame = 0; frame < 30 && resourceRequests.isEmpty; frame++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(resourceRequests, ['video']);
      expect(scanner.isVerifyingOriginals, isTrue);
      await tester.pump(const Duration(seconds: 6));
      for (var frame = 0; frame < 20 && scanner.isScanning; frame++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await verification;
      expect(scanner.pendingResourceCount, 1);
      expect(scanner.scanResult.allAssets.single.sizeKnown, isFalse);
      expect(
        nativeCancellations.any((args) => args.containsKey('token')),
        isTrue,
      );
      resourceResponse!.complete(inspected('late-video', size: 12345678));
      await tester.pump();
      expect(scanner.scanResult.allAssets.single.size, 0);
    },
  );

  testWidgets(
    'a timed-out page preserves indexed results and ignores its late response',
    (tester) async {
      library = List.generate(250, (index) => photo('asset-$index'));
      var blocked = false;
      scanner.addListener(() {
        if (!blocked && scanner.scannedAssetCount == 120) {
          blocked = true;
          pageResponse = Completer<Map<String, Object>>();
        }
      });
      final scan = scanner.startFullScan();
      for (var frame = 0; frame < 30 && rangeEnds.length < 2; frame++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(scanner.scannedAssetCount, 120);
      await tester.pump(const Duration(seconds: 31));
      await scan;
      expect(scanner.hasCompletedScan, isFalse);
      expect(scanner.lastError, contains('逾時'));
      pageResponse!.complete({
        'data': [photo('late-page')],
      });
      await tester.pump();
      expect(scanner.scannedAssetCount, 120);
      expect(
        scanner.scanResult.allAssets.map((asset) => asset.id),
        isNot(contains('late-page')),
      );
    },
  );

  test(
    '42,683 assets are fully indexed with amortized snapshots and no original reads',
    () async {
      library = List.generate(42683, (i) => photo('asset-$i'));
      var snapshots = 0;
      var previous = scanner.scanResult;
      scanner.addListener(() {
        if (!identical(previous, scanner.scanResult)) {
          snapshots++;
          previous = scanner.scanResult;
        }
        // Repeated progress getter reads must not traverse the library.
        expectSync(scanner.totalPhotoCount, scanner.scannedAssetCount);
      });
      final clock = Stopwatch()..start();
      await scanner.startFullScan();
      expect(scanner.scannedAssetCount, 42683);
      expect(rangeEnds.last, 42683);
      expect(scanner.attemptedAnalysisCount, 42683);
      expect(scanner.cloudPendingCount, 42683);
      expect(scanner.pendingResourceCount, 42683);
      expect(scanner.attemptedResourceCount, 0);
      expect(resourceRequests, isEmpty);
      expect(
        scanner.scanResult.allAssets.every((a) => a.thumbnail == null),
        isTrue,
      );
      expect(
        snapshots,
        lessThan(100),
        reason: 'No whole-library copy per eight assets.',
      );
      expect(clock.elapsed, lessThan(const Duration(seconds: 15)));
    },
  );

  test(
    'slow first original cannot block usable local previews in the first batch',
    () async {
      library = [photo('slow'), photo('local-a'), photo('local-b')];
      resourceResponse = Completer<Map<String, Object>>();
      final bytes = preview();
      previewHandler = (ids) async {
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        return {
          'assets': ids
              .map(
                (id) => {
                  'assetId': id,
                  'status': id == 'slow' ? 'timeout' : 'local',
                  if (id != 'slow') 'thumbnail': bytes,
                },
              )
              .toList(),
        };
      };
      final clock = Stopwatch()..start();
      await scanner.startFullScan();
      expect(clock.elapsed, lessThan(const Duration(seconds: 3)));
      expect(scanner.analyzedAssetCount, 2);
      expect(scanner.attemptedAnalysisCount, 3);
      expect(scanner.pendingAnalysisCount, 1);
      expect(scanner.scanResult.similarGroups.single.assets, hasLength(2));
      expect(scanner.verifiedOriginalCount, 0);
      expect(resourceRequests, isEmpty);
      resourceResponse!.complete(inspected('unrequested-original'));
    },
  );

  test(
    'degraded thumbnails form review candidates without quality or best suggestions',
    () async {
      nativeResults = {
        'first': {...inspected('a'), 'thumbnailDegraded': true},
        'second': {...inspected('b'), 'thumbnailDegraded': true},
      };
      await scanner.startFullScan();
      final group = scanner.scanResult.similarGroups.single;
      expect(group.bestAssetId, isNull);
      expect(group.bestReason, isNull);
      expect(
        group.assets.every((a) => a.previewDegraded && a.qualityScore == 0),
        isTrue,
      );
      expect(scanner.scanResult.blurryPhotos, isEmpty);
      expect(scanner.scanResult.darkPhotos, isEmpty);
    },
  );

  testWidgets(
    '42k timeout-heavy scan has a 30-second round and resumes at the untouched tail',
    (tester) async {
      library = List.generate(42683, (i) => photo('asset-$i'));
      previewHandler = (ids) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return {
          'assets': ids
              .map((id) => {'assetId': id, 'status': 'timeout'})
              .toList(),
        };
      };
      final scan = scanner.startFullScan();
      for (var i = 0; i < 500 && previewRequests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(scanner.scannedAssetCount, 42683);
      expect(previewRequests, hasLength(1));
      await tester.pump(const Duration(seconds: 1));
      expect(scanner.currentWaitSeconds, greaterThanOrEqualTo(1));
      expect(scanner.attemptedAnalysisCount, 0);
      for (var i = 0; i < 17 && scanner.isScanning; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
      await scan;
      expect(scanner.isScanning, isFalse);
      expect(scanner.hasCompletedScan, isFalse);
      expect(scanner.lastError, contains('30 秒'));
      final processed = scanner.attemptedAnalysisCount;
      expect(processed, inInclusiveRange(8, 120));
      expect(scanner.pendingAnalysisCount, 42683);
      expect(resourceRequests, isEmpty);
      // Drain any obsolete mock completion; it cannot change counters or groups.
      await tester.pump(const Duration(seconds: 3));
      expect(scanner.attemptedAnalysisCount, processed);
      final before = previewRequests.length;
      previewResponse = Completer<Map<String, Object>>();
      final resumed = scanner.resumeScan();
      for (var i = 0; i < 500 && previewRequests.length == before; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(previewRequests.last.first, 'asset-$processed');
      scanner.cancelScan();
      await resumed;
      final countAfterCancel = scanner.attemptedAnalysisCount;
      previewResponse!.complete({
        'assets': [
          {
            'assetId': 'asset-$processed',
            'status': 'local',
            'thumbnail': preview(),
          },
        ],
      });
      await tester.pump();
      expect(scanner.attemptedAnalysisCount, countAfterCancel);
      expect(scanner.analyzedAssetCount, 0);
    },
  );

  testWidgets(
    'missing native preview callbacks time out per batch and still obey the total budget',
    (tester) async {
      library = List.generate(400, (i) => photo('asset-$i'));
      previewResponse = Completer<Map<String, Object>>();
      final scan = scanner.startFullScan();
      for (var i = 0; i < 30 && previewRequests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      for (var i = 0; i < 14 && scanner.isScanning; i++) {
        await tester.pump(const Duration(milliseconds: 2500));
      }
      await scan;
      expect(scanner.isScanning, isFalse);
      expect(scanner.attemptedAnalysisCount, greaterThan(8));
      expect(scanner.attemptedAnalysisCount, lessThan(100));
      expect(scanner.currentOperation, isNull);
      expect(
        nativeCancellations.where((c) => c.containsKey('token')),
        isNotEmpty,
      );
      final count = scanner.attemptedAnalysisCount;
      previewResponse!.complete({
        'assets': [
          {'assetId': 'asset-0', 'status': 'local', 'thumbnail': preview()},
        ],
      });
      await tester.pump();
      expect(scanner.attemptedAnalysisCount, count);
      expect(scanner.analyzedAssetCount, 0);
    },
  );

  testWidgets(
    'original verification has a separate 60-second budget and retains attempted failures',
    (tester) async {
      library = List.generate(400, (i) => photo('asset-$i', type: 2));
      final initial = scanner.startFullScan();
      for (var i = 0; i < 30 && scanner.isScanning; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await initial;
      resourceResponse = Completer<Map<String, Object>>();
      final verification = scanner.verifyOriginals();
      for (var i = 0; i < 30 && resourceRequests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      for (var i = 0; i < 14 && scanner.isScanning; i++) {
        await tester.pump(const Duration(seconds: 5));
      }
      await verification;
      expect(scanner.lastError, contains('60 秒'));
      final attempted = scanner.attemptedResourceCount;
      expect(attempted, inInclusiveRange(1, 12));
      expect(scanner.verifiedOriginalCount, 0);
      expect(scanner.pendingResourceCount, 400);
      final calls = resourceRequests.length;
      final resumed = scanner.verifyOriginals();
      for (var i = 0; i < 30 && resourceRequests.length == calls; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(resourceRequests.last, 'asset-$attempted');
      scanner.cancelScan();
      await resumed;
      resourceResponse!.complete(inspected('late-original'));
      await tester.pump();
      expect(scanner.verifiedOriginalCount, 0);
    },
  );

  test(
    'interrupted resume preserves the hidden verified checkpoint beyond its visible index',
    () async {
      library = List.generate(250, (i) => photo('video-$i', type: 2));
      nativeResults = {
        for (var i = 0; i < 250; i++)
          'video-$i': {'complete': true, 'sizeKnown': true, 'size': 1000 + i},
      };
      await scanner.startFullScan();
      await scanner.verifyOriginals();
      expect(scanner.verifiedOriginalCount, 250);
      var blocked = false;
      scanner.addListener(() {
        if (!blocked &&
            scanner.isScanning &&
            scanner.scannedAssetCount == 120) {
          blocked = true;
          pageResponse = Completer<Map<String, Object>>();
        }
      });
      final oldPageCount = rangeEnds.length;
      final partial = scanner.resumeScan();
      while (rangeEnds.length < oldPageCount + 2) {
        await Future<void>.delayed(Duration.zero);
      }
      scanner.cancelScan();
      await partial;
      expect(scanner.scannedAssetCount, 120);
      expect(scanner.verifiedOriginalCount, 120);
      final obsolete = pageResponse!;
      pageResponse = null;
      resourceRequests.clear();
      await scanner.verifyOriginals();
      expect(scanner.scannedAssetCount, 250);
      expect(scanner.verifiedOriginalCount, 250);
      expect(
        resourceRequests,
        isEmpty,
        reason: 'The unindexed tail retains its hidden checkpoint.',
      );
      obsolete.complete({
        'data': [photo('obsolete')],
      });
      await Future<void>.delayed(Duration.zero);
      expect(scanner.scannedAssetCount, 250);
    },
  );

  test(
    'original pending reason cannot overwrite the preview cloud status',
    () async {
      nativeResults = {
        'first': {
          'complete': false,
          'sizeKnown': false,
          'size': 0,
          'pendingReason': 'byte_budget_exceeded',
          'partialBytes': 67108864,
        },
        'second': inspected('local'),
      };
      await scanner.startFullScan();
      expect(scanner.cloudPendingCount, 1);
      await scanner.verifyOriginals();
      final first = scanner.scanResult.allAssets.firstWhere(
        (a) => a.id == 'first',
      );
      expect(first.pendingReason, 'not_local');
      expect(first.resourcePendingReason, 'byte_budget_exceeded');
      expect(first.sizeKnown, isFalse);
      expect(first.size, 0);
      expect(scanner.cloudPendingCount, 1);
      expect(scanner.attemptedResourceCount, 2);
    },
  );

  test(
    'unsupported platforms keep resource capacity unknown without invoking the iOS channel',
    () async {
      final subject = PhotoScannerService(supportsNativeResources: false);
      await subject.startFullScan();
      expect(resourceRequests, isEmpty);
      expect(
        subject.scanResult.allAssets.every((asset) => !asset.sizeKnown),
        isTrue,
      );
      expect(subject.scanNotice, contains('尚未提供本機原始素材分析'));
      subject.dispose();
    },
  );

  testWidgets(
    'a 42k photo index does not starve a large local video size check',
    (tester) async {
      library = [
        ...List.generate(42682, (i) => photo('photo-$i')),
        photo('large-video', type: 2, created: 1600000000),
      ];
      final slowPhoto = Completer<Map<String, Object>>();
      resourceHandler = (id) async => id == 'large-video'
          ? {
              'complete': true,
              'sizeComplete': true,
              'hashComplete': false,
              'sizeKnown': true,
              'size': 3 * 1024 * 1024 * 1024,
            }
          : slowPhoto.future;
      final verification = scanner.verifyOriginals();
      for (
        var frame = 0;
        frame < 1500 && resourceRequests.length < 2;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(scanner.scannedAssetCount, 42683);
      expect(resourceRequests.first, 'large-video');
      expect(resourceArguments.first['includeHash'], isFalse);
      expect(scanner.knownSizeAssetCount, 1);
      expect(scanner.pendingSizeAssetCount, 42682);
      expect(scanner.verifiedHashAssetCount, 0);
      expect(scanner.pendingHashAssetCount, 42682);
      expect(scanner.scanResult.largeFiles.single.id, 'large-video');
      expect(scanner.scanResult.largeFiles.single.size, 3221225472);
      scanner.cancelScan();
      await verification;
      slowPhoto.complete(inspected('late-hash'));
      await tester.pump();
      expect(scanner.knownSizeAssetCount, 1);
      expect(scanner.verifiedHashAssetCount, 0);
    },
  );

  test(
    'complete capacity survives incomplete hash verification and a failed retry',
    () async {
      library = [photo('size-only')];
      nativeResults = {
        'size-only': {
          'sizeKnown': true,
          'sizeComplete': true,
          'size': 120 * 1024 * 1024,
          'complete': false,
          'hashComplete': false,
          // Even a well-formed SHA must be ignored unless ALL content is verified.
          'hash': sha256.convert(utf8.encode('unverified-prefix')).toString(),
          'pendingReason': 'hash_byte_budget_exceeded',
        },
      };
      await scanner.verifyOriginals();
      final first = scanner.scanResult.allAssets.single;
      expect(first.sizeKnown, isTrue);
      expect(first.hash, isNull);
      expect(first.resourceAnalysisPending, isTrue);
      expect(scanner.knownSizeAssetCount, 1);
      expect(scanner.pendingSizeAssetCount, 0);
      expect(scanner.verifiedHashAssetCount, 0);
      expect(scanner.pendingHashAssetCount, 1);
      expect(scanner.scanResult.largeFiles.single.size, first.size);
      nativeResults = {};
      await scanner.verifyOriginals();
      final retried = scanner.scanResult.allAssets.single;
      expect(retried.sizeKnown, isTrue);
      expect(retried.size, 120 * 1024 * 1024);
      expect(retried.hash, isNull);
      expect(scanner.knownSizeAssetCount, 1);
      expect(scanner.scanResult.duplicateGroups, isEmpty);
    },
  );

  test(
    'verified SHA requires hash completeness while legacy full results stay compatible',
    () async {
      library = [photo('unverified'), photo('verified')];
      nativeResults = {
        'unverified': {...inspected('same'), 'hashComplete': false},
        'verified': inspected('same'),
      };
      await scanner.verifyOriginals();
      expect(scanner.knownSizeAssetCount, 2);
      expect(scanner.pendingSizeAssetCount, 0);
      expect(scanner.verifiedHashAssetCount, 1);
      expect(scanner.pendingHashAssetCount, 1);
      expect(scanner.scanResult.duplicateGroups, isEmpty);
      expect(
        scanner.scanResult.allAssets
            .firstWhere((a) => a.id == 'unverified')
            .hash,
        isNull,
      );
    },
  );

  for (final reason in [
    'asset_changed_during_analysis',
    'asset_unavailable',
    'original_resource_missing',
  ]) {
    test('explicit $reason invalidates previously measured capacity', () async {
      library = [photo('size-only')];
      nativeResults = {
        'size-only': {
          'sizeKnown': true,
          'sizeComplete': true,
          'size': 120 * 1024 * 1024,
          'complete': false,
          'hashComplete': false,
        },
      };
      await scanner.verifyOriginals();
      expect(scanner.knownSizeAssetCount, 1);
      nativeResults = {
        'size-only': {
          'complete': false,
          'sizeKnown': false,
          'pendingReason': reason,
        },
      };
      await scanner.verifyOriginals();
      expect(scanner.knownSizeAssetCount, 0);
      expect(scanner.pendingSizeAssetCount, 1);
      expect(scanner.scanResult.largeFiles, isEmpty);
      expect(scanner.scanResult.allAssets.single.size, 0);
      expect(scanner.scanResult.allAssets.single.sizeKnown, isFalse);
    });
  }

  test(
    'capacity and SHA counters stay correct after deletion and a same-ID edit',
    () async {
      nativeResults = {'first': inspected('same'), 'second': inspected('same')};
      await scanner.verifyOriginals();
      expect(scanner.knownSizeAssetCount, 2);
      expect(scanner.verifiedHashAssetCount, 2);
      deletedBySystem = ['first'];
      await scanner.deleteAssetsWithResult([
        scanner.scanResult.allAssets.firstWhere((a) => a.id == 'first'),
      ]);
      expect(scanner.knownSizeAssetCount, 1);
      expect(scanner.verifiedHashAssetCount, 1);
      library = [
        {...photo('second'), 'modifiedDt': 1900000000},
      ];
      nativeResults = {};
      await scanner.resumeScan();
      expect(scanner.knownSizeAssetCount, 0);
      expect(scanner.pendingSizeAssetCount, 1);
      expect(scanner.verifiedHashAssetCount, 0);
      expect(scanner.pendingHashAssetCount, 1);
    },
  );

  test(
    'partial streams without a size completion flag never become large-file capacity',
    () async {
      library = [photo('prefix', type: 2), photo('fractional', type: 2)];
      nativeResults = {
        'prefix': {'complete': false, 'sizeKnown': true, 'size': 104857600},
        'fractional': {
          'complete': true,
          'sizeKnown': true,
          'size': 104857600.5,
        },
      };
      await scanner.verifyOriginals();
      expect(scanner.knownSizeAssetCount, 0);
      expect(scanner.pendingSizeAssetCount, 2);
      expect(scanner.scanResult.largeFiles, isEmpty);
      expect(
        scanner.scanResult.allAssets.every((a) => a.size == 0 && !a.sizeKnown),
        isTrue,
      );
    },
  );

  testWidgets(
    'slow cloud videos do not monopolize all-target photo hash verification',
    (tester) async {
      library = [
        ...List.generate(100, (i) => photo('cloud-video-$i', type: 2)),
        photo('local-photo'),
      ];
      final slowVideo = Completer<Map<String, Object>>();
      resourceHandler = (id) async =>
          id == 'local-photo' ? inspected('photo-content') : slowVideo.future;
      final verification = scanner.verifyOriginals();
      for (var i = 0; i < 40 && resourceRequests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(resourceRequests.single, 'cloud-video-0');
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 10));
      final secondRequest = resourceRequests[1];
      scanner.cancelScan();
      await verification;
      slowVideo.complete({'complete': false, 'sizeKnown': false});
      await tester.pump();
      expect(secondRequest, 'local-photo');
    },
  );

  testWidgets('already attempted original retries rotate after cancellation', (
    tester,
  ) async {
    library = List.generate(3, (i) => photo('cloud-video-$i', type: 2));
    final initial = scanner.verifyOriginals();
    for (var i = 0; i < 40 && scanner.isScanning; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await initial;
    expect(resourceRequests, [
      'cloud-video-0',
      'cloud-video-1',
      'cloud-video-2',
    ]);
    resourceRequests.clear();
    final oldResponse = Completer<Map<String, Object>>();
    resourceResponse = oldResponse;
    final retry = scanner.verifyOriginals();
    for (var i = 0; i < 30 && resourceRequests.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(resourceRequests.single, 'cloud-video-0');
    scanner.cancelScan();
    await retry;
    resourceResponse = Completer<Map<String, Object>>();
    final resumed = scanner.verifyOriginals();
    for (var i = 0; i < 30 && resourceRequests.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    final nextRequest = resourceRequests.last;
    scanner.cancelScan();
    await resumed;
    oldResponse.complete(inspected('obsolete-video', size: 9000000));
    resourceResponse!.complete(inspected('late-video', size: 9000000));
    await tester.pump();
    expect(nextRequest, 'cloud-video-1');
    expect(scanner.knownSizeAssetCount, 0);
  });

  testWidgets(
    'exact-photo target bypasses 2006 cloud videos and verifies actual photo content',
    (tester) async {
      library = [
        ...List.generate(2006, (i) => photo('cloud-video-$i', type: 2)),
        photo('pair-a'),
        photo('pair-b'),
      ];
      nativeResults = {
        'pair-a': inspected('same-originals'),
        'pair-b': inspected('same-originals'),
      };
      final verification = scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      for (var i = 0; i < 100 && scanner.isScanning; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await verification;
      expect(resourceRequests, ['pair-a', 'pair-b']);
      expect(resourceArguments.every((a) => a['includeHash'] == true), isTrue);
      expect(scanner.verifiedHashAssetCount, 2);
      expect(scanner.pendingHashAssetCount, 0);
      expect(scanner.pendingSizeAssetCount, 2006);
      expect(scanner.pendingResourceCount, 2006);
      expect(scanner.scanResult.duplicateGroups.single.assets.length, 2);
    },
  );

  test(
    'size-only target never accepts a SHA and leaves photo hashes pending for exact verification',
    () async {
      library = [photo('photo'), photo('video', type: 2)];
      nativeResults = {
        'photo': inspected('not-requested-hash', size: 12000000),
        'video': inspected('video', size: 3000000000),
      };
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      expect(resourceRequests, ['video', 'photo']);
      expect(resourceArguments.every((a) => a['includeHash'] == false), isTrue);
      expect(scanner.knownSizeAssetCount, 2);
      expect(scanner.pendingSizeAssetCount, 0);
      expect(scanner.verifiedHashAssetCount, 0);
      expect(scanner.pendingHashAssetCount, 1);
      expect(scanner.pendingResourceCount, 1);
      expect(scanner.scanResult.allAssets.every((a) => a.hash == null), isTrue);
      expect(scanner.scanResult.largeFiles.length, 2);
      resourceRequests.clear();
      resourceArguments.clear();
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      expect(resourceRequests, ['photo']);
      expect(resourceArguments.single['includeHash'], isTrue);
      expect(scanner.verifiedHashAssetCount, 1);
      expect(scanner.pendingResourceCount, 0);
      resourceRequests.clear();
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      expect(resourceRequests, isEmpty);
      expect(scanner.verifiedHashAssetCount, 1);
    },
  );

  test(
    'exact metadata candidates are prioritized but different full content is never grouped',
    () async {
      library = [
        photo('unique-head', created: 1600000000),
        photo('candidate-a', created: 1700000000),
        photo('candidate-b', created: 1700000000),
      ];
      nativeResults = {
        'unique-head': inspected('unique'),
        'candidate-a': inspected('original-A'),
        'candidate-b': inspected('original-B'),
      };
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      expect(resourceRequests, ['candidate-a', 'candidate-b', 'unique-head']);
      expect(scanner.verifiedHashAssetCount, 3);
      expect(scanner.scanResult.duplicateGroups, isEmpty);
    },
  );

  testWidgets(
    'cancelled video retries are not blocked by ten thousand untouched size-only photos',
    (tester) async {
      library = [
        ...List.generate(10000, (i) => photo('photo-$i')),
        photo('cancelled-video', type: 2),
        photo('untouched-video', type: 2),
      ];
      var cancelled = false;
      scanner.addListener(() {
        if (!cancelled && scanner.attemptedResourceCount == 1) {
          cancelled = true;
          scanner.cancelScan();
        }
      });
      final first = scanner.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      for (var i = 0; i < 300 && scanner.isScanning; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await first;
      expect(scanner.wasCancelled, isTrue);
      expect(scanner.attemptedResourceCount, 1);
      expect(
        resourceRequests,
        isEmpty,
        reason: 'Cancel listeners prevent a new native request.',
      );
      final slow = Completer<Map<String, Object>>();
      resourceHandler = (id) async {
        if (id.endsWith('video')) {
          return {'complete': true, 'sizeKnown': true, 'size': 3000000000};
        }
        if (id == 'photo-0') return {'complete': false, 'sizeKnown': false};
        return slow.future;
      };
      final resumed = scanner.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      for (var i = 0; i < 300 && resourceRequests.length < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(resourceRequests.take(3), [
        'untouched-video',
        'photo-0',
        'cancelled-video',
      ]);
      expect(scanner.knownSizeAssetCount, 2);
      scanner.cancelScan();
      await resumed;
      slow.complete(inspected('late', size: 9000000));
      await tester.pump();
      expect(scanner.knownSizeAssetCount, 2);
      expect(scanner.verifiedHashAssetCount, 0);
      expect(
        scanner.scanResult.largeFiles.map((a) => a.id),
        containsAll(['cancelled-video', 'untouched-video']),
      );
    },
  );

  testWidgets(
    'cancelled exact pass publishes the fast verified pair before a slow third item completes',
    (tester) async {
      library = [photo('pair-a'), photo('pair-b'), photo('slow-third')];
      final slow = Completer<Map<String, Object>>();
      resourceHandler = (id) async =>
          id == 'slow-third' ? slow.future : inspected('same-originals');
      final verification = scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      for (var i = 0; i < 40 && resourceRequests.length < 3; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(scanner.verifiedHashAssetCount, 2);
      scanner.cancelScan();
      await verification;
      slow.complete(inspected('obsolete-third'));
      await tester.pump();
      expect(scanner.verifiedHashAssetCount, 2);
      expect(
        scanner.scanResult.duplicateGroups.single.assets.map((a) => a.id),
        containsAll(['pair-a', 'pair-b']),
      );
    },
  );

  testWidgets(
    'cancelling a slow original checkpoints its attempt and resumes untouched work',
    (tester) async {
      library = [photo('slow-first'), photo('untouched-second')];
      resourceResponse = Completer<Map<String, Object>>();
      final first = scanner.verifyOriginals();
      for (var i = 0; i < 30 && resourceRequests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(resourceRequests.single, 'slow-first');
      expect(scanner.attemptedResourceCount, 1);
      scanner.cancelScan();
      await first;
      final oldResponse = resourceResponse!;
      resourceResponse = Completer<Map<String, Object>>();
      final resumed = scanner.verifyOriginals();
      for (var i = 0; i < 30 && resourceRequests.length == 1; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(resourceRequests.last, 'untouched-second');
      oldResponse.complete(inspected('obsolete'));
      await tester.pump();
      expect(scanner.knownSizeAssetCount, 0);
      scanner.cancelScan();
      await resumed;
      resourceResponse!.complete(inspected('late-second'));
      await tester.pump();
      expect(scanner.knownSizeAssetCount, 0);
      expect(scanner.verifiedHashAssetCount, 0);
    },
  );
}
