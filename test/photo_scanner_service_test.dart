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
  late List<Map> albumFilters;
  late List<Map> rangeFilters;
  var honorRequestedOrder = false;

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

  bool isInPlaceContinuation() {
    final operation = scanner.currentOperation;
    final match = RegExp(r'^分析本機預覽（(\d+) 張）$').firstMatch(operation ?? '');
    return match != null &&
        int.parse(match.group(1)!) > 32 &&
        scanner.attemptedAnalysisCount > 0;
  }

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
    albumFilters = [];
    rangeFilters = [];
    honorRequestedOrder = false;
    messenger.setMockMethodCallHandler(resources, (call) async {
      final args = call.arguments as Map;
      if (call.method == 'cancelInspections') {
        nativeCancellations.add(args);
        return null;
      }
      if (call.method == 'inspectPreviews') {
        final ids = List<String>.from(args['assetIds'] as List);
        if (ids.isEmpty ||
            ids.length > 32 ||
            ids.toSet().length != ids.length) {
          throw PlatformException(
            code: 'arguments',
            message: 'iOS accepts 1–32 distinct preview identifiers',
          );
        }
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
        case 'getPermissionState':
          return permission.index;
        case 'getAssetPathList':
          final option = (call.arguments as Map)['option'] as Map;
          albumFilters.add(Map.of(option['child'] as Map));
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
          final filter = Map.of((args['option'] as Map)['child'] as Map);
          rangeFilters.add(filter);
          final start = args['start'] as int;
          final end = args['end'] as int;
          rangeEnds.add(end);
          final ordered = List<Map<String, Object>>.of(library);
          if (honorRequestedOrder &&
              (filter['orders'] as List).any(
                (order) => order['type'] == 0 && order['asc'] == false,
              )) {
            ordered.sort(
              (a, b) => (b['createDt'] as int).compareTo(a['createDt'] as int),
            );
          }
          return pageResponse == null
              ? {'data': ordered.sublist(start, end)}
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

  test(
    'permission changes clear revoked results without requesting again',
    () async {
      await scanner.startFullScan();
      expect(scanner.scanResult.allAssets, hasLength(2));
      permission = PermissionState.limited;
      await scanner.refreshPhotoAccess();
      expect(scanner.hasLimitedAccess, isTrue);
      expect(scanner.scanResult.allAssets, isEmpty);
      expect(scanner.hasCompletedScan, isFalse);
      permission = PermissionState.denied;
      await scanner.refreshPhotoAccess();
      expect(scanner.permissionDenied, isTrue);
      expect(scanner.knownLibraryBytes, 0);
      permission = PermissionState.authorized;
      await scanner.refreshPhotoAccess();
      expect(scanner.permissionDenied, isFalse);
      expect(scanner.scanResult.allAssets, isEmpty);
    },
  );

  test(
    'verified byte count is retained once and removed only for actual deletions',
    () async {
      library = [photo('a'), photo('b')];
      nativeResults = {
        'a': inspected('a', size: 100),
        'b': inspected('b', size: 200),
      };
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      expect(scanner.knownLibraryBytes, 300);
      expect(scanner.knownSizeAssetCount, 2);
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      expect(scanner.knownLibraryBytes, 300);
      deletedBySystem = ['a'];
      await scanner.deleteAssetsWithResult(scanner.scanResult.allAssets);
      expect(scanner.knownLibraryBytes, 200);
      expect(scanner.scanResult.allAssets.map((asset) => asset.id), ['b']);
    },
  );

  test(
    'limited-to-limited Settings changes invalidate old access and require a new scan',
    () async {
      permission = PermissionState.limited;
      await scanner.startFullScan();
      final old = scanner.scanResult.allAssets;
      library = [photo('first'), photo('replacement')];
      final pagesBefore = rangeEnds.length;
      await scanner.refreshPhotoAccess();
      expect(scanner.hasLimitedAccess, isTrue);
      expect(scanner.photoScopeChanged, isTrue);
      expect(scanner.scanResult.allAssets, isEmpty);
      expect(
        rangeEnds,
        hasLength(pagesBefore + 1),
        reason: 'Refresh reads metadata to detect same-count scope changes.',
      );
      expect(await scanner.deleteAssetsWithResult(old), isEmpty);
      expect(deletionRequests, isEmpty);
      await scanner.startFullScan();
      expect(scanner.scanResult.allAssets.map((a) => a.id), [
        'first',
        'replacement',
      ]);
      expect(scanner.photoScopeChanged, isFalse);
    },
  );

  test(
    'unchanged limited scope preserves snapshot hashes bytes and checkpoints without media reads',
    () async {
      permission = PermissionState.limited;
      nativeResults = {
        'first': inspected('first-content', size: 100),
        'second': inspected('second-content', size: 200),
      };
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      final snapshot = scanner.scanResult;
      expect(scanner.verifiedHashAssetCount, 2);
      expect(scanner.knownLibraryBytes, 300);
      resourceRequests.clear();
      previewRequests.clear();
      rangeEnds.clear();
      await scanner.refreshPhotoAccess();
      expect(identical(scanner.scanResult, snapshot), isTrue);
      expect(scanner.photoScopeChanged, isFalse);
      expect(scanner.verifiedHashAssetCount, 2);
      expect(scanner.knownLibraryBytes, 300);
      expect(resourceRequests, isEmpty);
      expect(previewRequests, isEmpty);
      expect(rangeEnds, [2]);
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      expect(
        resourceRequests,
        isEmpty,
        reason: 'Validated checkpoints remain reusable.',
      );
      expect(scanner.verifiedHashAssetCount, 2);
      expect(scanner.knownLibraryBytes, 300);
    },
  );

  test(
    'limited foreground check pages metadata and preserves an unchanged large scope',
    () async {
      permission = PermissionState.limited;
      library = List.generate(241, (i) => photo('metadata-$i'));
      await scanner.startFullScan();
      final snapshot = scanner.scanResult;
      resourceRequests.clear();
      previewRequests.clear();
      rangeEnds.clear();
      await scanner.refreshPhotoAccess();
      expect(identical(scanner.scanResult, snapshot), isTrue);
      expect(rangeEnds, [120, 240, 241]);
      expect(resourceRequests, isEmpty);
      expect(previewRequests, isEmpty);
    },
  );

  test(
    'same-count limited scope invalidates a same-ID photo edited in Photos',
    () async {
      permission = PermissionState.limited;
      await scanner.startFullScan();
      library = [
        {...photo('first'), 'modifiedDt': 1900000000},
        photo('second'),
      ];
      await scanner.refreshPhotoAccess();
      expect(scanner.scanResult.allAssets, isEmpty);
      expect(scanner.photoScopeChanged, isTrue);
    },
  );

  testWidgets(
    'limited scope metadata timeout clears stale state and ignores late results',
    (tester) async {
      permission = PermissionState.limited;
      await tester.runAsync(scanner.startFullScan);
      pageResponse = Completer<Map<String, Object>>();
      final latePage = pageResponse!;
      final pagesBefore = rangeEnds.length;
      final refreshing = scanner.refreshPhotoAccess();
      for (var i = 0; i < 50 && rangeEnds.length == pagesBefore; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(rangeEnds.length, pagesBefore + 1);
      await tester.pump(const Duration(seconds: 6));
      await refreshing;
      expect(scanner.scanResult.allAssets, isEmpty);
      expect(scanner.photoScopeChanged, isTrue);
      latePage.complete({'data': library});
      await tester.pump();
      expect(scanner.scanResult.allAssets, isEmpty);
      pageResponse = null;
      await tester.runAsync(scanner.startFullScan);
      final current = scanner.scanResult;
      await tester.runAsync(scanner.refreshPhotoAccess);
      expect(
        identical(scanner.scanResult, current),
        isTrue,
        reason: 'The timeout releases the serialized access checker.',
      );
    },
  );

  testWidgets(
    'scan beginning during a limited scope check supersedes its old result',
    (tester) async {
      permission = PermissionState.limited;
      await tester.runAsync(scanner.startFullScan);
      pageResponse = Completer<Map<String, Object>>();
      final oldPage = pageResponse!;
      final pagesBefore = rangeEnds.length;
      final refreshing = scanner.refreshPhotoAccess();
      for (var i = 0; i < 50 && rangeEnds.length == pagesBefore; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(rangeEnds.length, pagesBefore + 1);
      pageResponse = null;
      library = [photo('new-first'), photo('new-second')];
      await tester.runAsync(scanner.startFullScan);
      final current = scanner.scanResult;
      oldPage.complete({
        'data': [photo('stale-a'), photo('stale-b')],
      });
      await tester.pump();
      await refreshing;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(identical(scanner.scanResult, current), isTrue);
      expect(scanner.scanResult.allAssets.map((a) => a.id), [
        'new-first',
        'new-second',
      ]);
      expect(scanner.photoScopeChanged, isFalse);
    },
  );

  testWidgets(
    'foreground permission refresh waits for scan cancellation and ignores late work',
    (tester) async {
      resourceResponse = Completer<Map<String, Object>>();
      final scan = scanner.verifyOriginals();
      for (var i = 0; i < 50 && resourceRequests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(scanner.isScanning, isTrue);
      permission = PermissionState.denied;
      await scanner.refreshPhotoAccess();
      expect(scanner.permissionDenied, isFalse);
      scanner.cancelScan();
      await scan;
      await tester.pump();
      expect(scanner.permissionDenied, isTrue);
      expect(scanner.scanResult.allAssets, isEmpty);
      resourceResponse!.complete(inspected('late'));
      await tester.pump();
      expect(scanner.scanResult.allAssets, isEmpty);
    },
  );

  test(
    'foreground permission revocation stops a continuous scan and clears its old scope',
    () async {
      library = List.generate(104, (i) => photo('old-$i'));
      previewResponse = Completer<Map<String, Object>>();
      final latePreview = previewResponse!;
      final scan = scanner.startContinuousScan();
      for (var i = 0; i < 100 && previewRequests.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(previewRequests, isNotEmpty);
      expect(scanner.scanResult.allAssets, hasLength(104));
      permission = PermissionState.denied;
      await scanner.refreshPhotoAccess();
      await scan;
      for (var i = 0; i < 100 && !scanner.permissionDenied; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(scanner.permissionDenied, isTrue);
      expect(scanner.scanResult.allAssets, isEmpty);
      expect(scanner.isScanning, isFalse);
      latePreview.complete({
        'assets': [
          {'assetId': 'old-0', 'status': 'local', 'thumbnail': preview()},
        ],
      });
      await Future<void>.delayed(Duration.zero);
      expect(scanner.scanResult.allAssets, isEmpty);
    },
  );

  test(
    'unchanged foreground permission resumes a paused continuous scan',
    () async {
      library = List.generate(40, (i) => photo('photo-$i'));
      previewResponse = Completer<Map<String, Object>>();
      final latePreview = previewResponse!;
      final scan = scanner.startContinuousScan();
      for (var i = 0; i < 100 && previewRequests.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(previewRequests, hasLength(1));
      previewResponse = null;
      await scanner.refreshPhotoAccess();
      await scan;
      for (var i = 0; i < 100 && scanner.isScanning; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(scanner.hasCompletedScan, isTrue);
      expect(scanner.attemptedAnalysisCount, 40);
      expect(previewRequests.length, greaterThan(1));
      latePreview.complete({'assets': []});
    },
  );

  test(
    'foreground refresh does not undo an explicit scan cancellation',
    () async {
      previewResponse = Completer<Map<String, Object>>();
      final latePreview = previewResponse!;
      final scan = scanner.startContinuousScan();
      for (var i = 0; i < 100 && previewRequests.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(previewRequests, hasLength(1));
      scanner.cancelScan();
      await scanner.refreshPhotoAccess();
      await scan;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(scanner.isScanning, isFalse);
      expect(scanner.wasCancelled, isTrue);
      expect(previewRequests, hasLength(1));
      latePreview.complete({'assets': []});
    },
  );

  test(
    'permission refresh waits for native deletion to finish before invalidating access',
    () async {
      await scanner.startFullScan();
      deletionResponse = Completer<List<String>>();
      final delete = scanner.deleteAssetsWithResult(
        scanner.scanResult.allAssets,
      );
      await Future<void>.delayed(Duration.zero);
      permission = PermissionState.denied;
      await scanner.refreshPhotoAccess();
      expect(scanner.isDeleting, isTrue);
      expect(scanner.scanResult.allAssets, hasLength(2));
      deletionResponse!.complete(['first']);
      expect(await delete, {'first'});
      await Future<void>.delayed(Duration.zero);
      expect(scanner.permissionDenied, isTrue);
      expect(scanner.scanResult.allAssets, isEmpty);
    },
  );

  test('deletion rejects an older version of a same-ID edited asset', () async {
    await scanner.startFullScan();
    final stale = scanner.scanResult.allAssets.first;
    library = [
      {...photo('first'), 'modifiedDt': 1900000000},
    ];
    await scanner.resumeScan();
    expect(await scanner.deleteAssetsWithResult([stale]), isEmpty);
    expect(deletionRequests, isEmpty);
  });

  testWidgets(
    'capacity attempts cannot fill a new photo-only verification round',
    (tester) async {
      library = [photo('a'), photo('b'), photo('v', type: 2)];
      nativeResults = {
        'a': inspected('a', size: 100),
        'b': inspected('b', size: 200),
        'v': inspected('v', size: 300),
      };
      await tester.runAsync(
        () => scanner.verifyOriginals(
          target: OriginalVerificationTarget.fileSizes,
        ),
      );
      expect(scanner.originalRoundTotal, 3);
      expect(scanner.originalRoundProcessed, 3);
      expect(scanner.verifiedHashAssetCount, 0);
      expect(scanner.knownLibraryBytes, 600);
      resourceRequests.clear();
      resourceResponse = Completer<Map<String, Object>>();
      final hashRound = scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      for (var i = 0; i < 30 && resourceRequests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(
        scanner.originalVerificationTarget,
        OriginalVerificationTarget.exactPhotos,
      );
      expect(scanner.originalRoundTotal, 2);
      expect(scanner.originalRoundProcessed, 0);
      expect(scanner.attemptedResourceCount, 3);
      expect(resourceRequests, isNot(contains('v')));
      scanner.cancelScan();
      await hashRound;
      resourceResponse!.complete(inspected('late'));
      await tester.pump();
      expect(scanner.originalRoundProcessed, 0);
    },
  );

  test(
    'metadata version and video duration are available for review checkpoints',
    () async {
      library = [
        {...photo('v', type: 2), 'duration': 123},
      ];
      await scanner.startFullScan();
      final asset = scanner.scanResult.videos.single;
      expect(
        asset.modifiedDate,
        DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
      );
      expect(asset.durationSeconds, 123);
      expect(asset.copyWith(size: 10).modifiedDate, asset.modifiedDate);
      expect(asset.copyWith(size: 10).durationSeconds, 123);
    },
  );

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
    'large preview queue publishes eight items first then uses bounded wider batches',
    () async {
      library = List.generate(104, (i) => photo('asset-$i'));
      await scanner.startFullScan();
      expect(previewRequests.map((batch) => batch.length), [8, 32, 32, 32]);
      expect(previewRequests.expand((batch) => batch).toSet(), hasLength(104));
      expect(scanner.attemptedAnalysisCount, 104);
      expect(scanner.pendingAnalysisCount, 104);
      expect(resourceRequests, isEmpty);
    },
  );

  test(
    'wide native preview batch has time for a delayed two-wave response',
    () async {
      library = List.generate(40, (i) => photo('asset-$i'));
      final localPreview = preview();
      previewHandler = (ids) async {
        if (ids.length == 32) {
          await Future<void>.delayed(const Duration(seconds: 3));
        }
        return {
          'assets': ids
              .map(
                (id) => {
                  'assetId': id,
                  'status': id == 'asset-39' ? 'local' : 'not_local',
                  if (id == 'asset-39') 'thumbnail': localPreview,
                },
              )
              .toList(),
        };
      };
      await scanner.startFullScan();
      expect(previewRequests.map((batch) => batch.length), [8, 32]);
      expect(scanner.attemptedAnalysisCount, 40);
      expect(scanner.analyzedAssetCount, 1);
      expect(nativeCancellations.where((c) => c.containsKey('token')), isEmpty);
    },
  );

  test(
    'native wide-batch deadline leaves queued photos for the next automatic round',
    () async {
      library = List.generate(40, (i) => photo('asset-$i'));
      var firstWideBatch = true;
      previewHandler = (ids) async {
        final queued = ids.length == 32 && firstWideBatch;
        if (queued) firstWideBatch = false;
        return {
          'assets': [
            for (var i = 0; i < ids.length; i++)
              {
                'assetId': ids[i],
                'status': queued && i >= 16 ? 'not_started' : 'not_local',
              },
          ],
        };
      };
      await scanner.startContinuousScan();
      expect(previewRequests.map((batch) => batch.length), [8, 32, 8, 8]);
      expect(scanner.attemptedAnalysisCount, 40);
      expect(scanner.hasCompletedScan, isTrue);
      expect(scanner.cloudPendingCount, 40);
      expect(
        albumFilters,
        hasLength(2),
        reason: 'The queued tail should continue in place, then validate.',
      );
    },
  );

  test(
    'missing native preview rows never count as attempted analysis',
    () async {
      library = List.generate(40, (i) => photo('photo-$i'));
      previewHandler = (ids) async => {'assets': <Map<String, Object>>[]};
      await scanner.startContinuousScan();
      expect(previewRequests.length, greaterThanOrEqualTo(2));
      expect(scanner.attemptedAnalysisCount, 0);
      expect(scanner.analyzedAssetCount, 0);
      expect(scanner.pendingAnalysisCount, 40);
      expect(scanner.hasCompletedScan, isFalse);
      expect(resourceRequests, isEmpty);
    },
  );

  test(
    '42,638 mixed items expose a local pair early despite cloud misses and a large video',
    () async {
      library = [
        photo('pair-a'),
        photo('pair-b'),
        ...List.generate(42635, (i) => photo('cloud-$i')),
        photo('large-video', type: 2, created: 1600000000),
      ];
      final localPreview = preview();
      previewHandler = (ids) async {
        if (previewRequests.length == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 900));
        }
        return {
          'assets': ids
              .map(
                (id) => {
                  'assetId': id,
                  'status': id.startsWith('pair-')
                      ? 'local'
                      : id.hashCode.isEven
                      ? 'not_local'
                      : 'timeout',
                  if (id.startsWith('pair-')) 'thumbnail': localPreview,
                },
              )
              .toList(),
        };
      };
      int? firstPairAtAttempts;
      scanner.addListener(() {
        if (firstPairAtAttempts == null &&
            scanner.scanResult.similarGroups.isNotEmpty) {
          firstPairAtAttempts = scanner.attemptedAnalysisCount;
        }
      });
      await scanner.startFullScan();
      expect(scanner.scannedAssetCount, 42638);
      expect(firstPairAtAttempts, 8);
      expect(previewRequests.first, hasLength(8));
      expect(previewRequests[1], hasLength(32));
      expect(scanner.cloudPendingCount, greaterThan(1000));
      expect(
        scanner.scanResult.similarGroups.single.assets.map((a) => a.id),
        containsAll(['pair-a', 'pair-b']),
      );
      expect(scanner.scanResult.duplicateGroups, isEmpty);
      expect(scanner.scanResult.largeFiles, isEmpty);

      resourceHandler = (id) async => id.startsWith('pair-')
          ? inspected('identical-original', size: 7800000)
          : id == 'large-video'
          ? {
              'complete': true,
              'sizeComplete': true,
              'sizeKnown': true,
              'hashComplete': false,
              'size': 3 * 1024 * 1024 * 1024,
            }
          : {
              'complete': false,
              'sizeKnown': false,
              'pendingReason': 'local_resource_unavailable',
            };
      final exactRequestsAtStart = resourceRequests.length;
      void stopWhenPairVerified() {
        if (scanner.isScanning && scanner.verifiedHashAssetCount == 2) {
          scanner.cancelScan();
        }
      }

      scanner.addListener(stopWhenPairVerified);
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      scanner.removeListener(stopWhenPairVerified);
      expect(resourceRequests.skip(exactRequestsAtStart).take(2), [
        'pair-a',
        'pair-b',
      ]);
      expect(scanner.scanResult.duplicateGroups.single.assets, hasLength(2));

      void stopWhenVideoMeasured() {
        if (scanner.isScanning && scanner.knownSizeAssetCount == 3) {
          scanner.cancelScan();
        }
      }

      scanner.addListener(stopWhenVideoMeasured);
      final sizeRequestsAtStart = resourceRequests.length;
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      scanner.removeListener(stopWhenVideoMeasured);
      expect(resourceRequests[sizeRequestsAtStart], 'large-video');
      expect(scanner.scanResult.largeFiles.first.id, 'large-video');
      expect(scanner.scanResult.largeFiles.first.size, 3221225472);
    },
  );

  test(
    'first size round favors locally previewable high-resolution photos over cloud misses',
    () async {
      library = [
        {...photo('cloud-ultra'), 'width': 8000, 'height': 6000},
        {...photo('local-small'), 'width': 2000, 'height': 1000},
        {...photo('local-large'), 'width': 6000, 'height': 4000},
      ];
      final localPreview = preview();
      previewHandler = (ids) async => {
        'assets': ids
            .map(
              (id) => {
                'assetId': id,
                'status': id == 'cloud-ultra' ? 'not_local' : 'local',
                if (id != 'cloud-ultra') 'thumbnail': localPreview,
              },
            )
            .toList(),
      };
      await scanner.startFullScan();
      resourceHandler = (id) async =>
          inspected(id, size: id == 'local-large' ? 30000000 : 6000000);
      void stopAfterFirstSize() {
        if (scanner.isScanning && scanner.knownSizeAssetCount == 1) {
          scanner.cancelScan();
        }
      }

      scanner.addListener(stopAfterFirstSize);
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      scanner.removeListener(stopAfterFirstSize);
      expect(resourceRequests.single, 'local-large');
      expect(scanner.scanResult.largeFiles.single.id, 'local-large');
      expect(scanner.pendingSizeAssetCount, 2);
    },
  );

  test(
    'continuous scan crosses round deadlines without retrying completed cloud misses',
    () async {
      scanner.dispose();
      scanner = PhotoScannerService(
        supportsNativeResources: true,
        continuousPreviewRoundBudget: const Duration(milliseconds: 500),
        continuousScanBudget: const Duration(seconds: 10),
      );
      library = List.generate(104, (i) => photo('cloud-$i'));
      var sawInPlaceRound = false;
      var hadVisibleResults = false;
      var blankedAfterResults = false;
      scanner.addListener(() {
        sawInPlaceRound |= isInPlaceContinuation();
        hadVisibleResults |=
            scanner.attemptedAnalysisCount > 0 &&
            scanner.scanResult.allAssets.isNotEmpty;
        if (hadVisibleResults && scanner.scanResult.allAssets.isEmpty) {
          blankedAfterResults = true;
        }
      });
      previewHandler = (ids) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return {
          'assets': ids
              .map((id) => {'assetId': id, 'status': 'not_local'})
              .toList(),
        };
      };
      await scanner.startContinuousScan();
      expect(
        sawInPlaceRound,
        isTrue,
        reason: 'A bounded round should continue without another tap.',
      );
      expect(blankedAfterResults, isFalse);
      expect(
        albumFilters,
        hasLength(2),
        reason:
            'Only initial indexing and final validation may page the scope.',
      );
      expect(scanner.scannedAssetCount, 104);
      expect(scanner.attemptedAnalysisCount, 104);
      expect(scanner.cloudPendingCount, 104);
      expect(scanner.hasCompletedScan, isTrue);
      expect(scanner.isScanning, isFalse);
      expect(resourceRequests, isEmpty);
      // Completed cloud misses are not re-read in later rounds.
      final completedIds = previewRequests.expand((batch) => batch).toList();
      expect(completedIds.where((id) => id == 'cloud-0'), hasLength(1));

      previewRequests.clear();
      final recoveredPreview = preview();
      previewHandler = (ids) async => {
        'assets': ids
            .map(
              (id) => {
                'assetId': id,
                'status': id == 'cloud-0' ? 'local' : 'not_local',
                if (id == 'cloud-0') 'thumbnail': recoveredPreview,
              },
            )
            .toList(),
      };
      await scanner.startContinuousScan(resume: true);
      expect(previewRequests.expand((batch) => batch), hasLength(104));
      expect(scanner.analyzedAssetCount, 1);
      expect(scanner.pendingAnalysisCount, 103);
      expect(
        scanner.scanResult.allAssets
            .firstWhere((a) => a.id == 'cloud-0')
            .analysisPending,
        isFalse,
      );
    },
  );

  test(
    '42,638-item second preview round retains results without re-indexing',
    () async {
      scanner.dispose();
      scanner = PhotoScannerService(
        supportsNativeResources: true,
        continuousPreviewRoundBudget: const Duration(milliseconds: 500),
        continuousScanBudget: const Duration(seconds: 10),
      );
      library = List.generate(42638, (i) => photo('asset-$i'));
      previewHandler = (ids) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return {
          'assets': ids
              .map((id) => {'assetId': id, 'status': 'not_local'})
              .toList(),
        };
      };
      var hadResults = false;
      var blanked = false;
      var secondRoundStarted = false;
      scanner.addListener(() {
        hadResults |=
            scanner.attemptedAnalysisCount > 0 &&
            scanner.scanResult.allAssets.length == 42638;
        if (hadResults && scanner.scanResult.allAssets.isEmpty) blanked = true;
        if (!secondRoundStarted && isInPlaceContinuation()) {
          secondRoundStarted = true;
          expect(scanner.scannedAssetCount, 42638);
          expect(scanner.scanResult.allAssets, hasLength(42638));
          scanner.cancelScan();
        }
      });
      await scanner.startContinuousScan();
      expect(secondRoundStarted, isTrue);
      expect(blanked, isFalse);
      expect(
        albumFilters,
        hasLength(1),
        reason: 'A same-scope next round must reuse the validated index.',
      );
      expect(scanner.wasCancelled, isTrue);
      expect(scanner.attemptedAnalysisCount, greaterThan(0));
    },
  );

  test(
    'an edit during an in-place round is re-indexed before continuous scan ends',
    () async {
      scanner.dispose();
      scanner = PhotoScannerService(
        supportsNativeResources: true,
        continuousPreviewRoundBudget: const Duration(milliseconds: 500),
        continuousScanBudget: const Duration(seconds: 10),
      );
      library = List.generate(104, (i) => photo('asset-$i'));
      previewHandler = (ids) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return {
          'assets': ids
              .map((id) => {'assetId': id, 'status': 'not_local'})
              .toList(),
        };
      };
      var changed = false;
      scanner.addListener(() {
        if (!changed && isInPlaceContinuation()) {
          changed = true;
          library[0] = photo('replacement');
        }
      });
      await scanner.startContinuousScan();
      expect(changed, isTrue);
      expect(
        albumFilters.length,
        greaterThanOrEqualTo(3),
        reason: 'Final scope comparison must trigger one safe re-index.',
      );
      expect(
        scanner.scanResult.allAssets.map((a) => a.id),
        contains('replacement'),
      );
      expect(
        scanner.scanResult.allAssets.map((a) => a.id),
        isNot(contains('asset-0')),
      );
    },
  );

  test(
    'continuous scan stops after repeated rounds with no native progress',
    () async {
      scanner.dispose();
      scanner = PhotoScannerService(
        supportsNativeResources: true,
        continuousPreviewRoundBudget: const Duration(milliseconds: 40),
        continuousScanBudget: const Duration(seconds: 3),
      );
      library = List.generate(104, (i) => photo('cloud-$i'));
      previewResponse = Completer<Map<String, Object>>();
      final clock = Stopwatch()..start();
      await scanner.startContinuousScan();
      expect(clock.elapsed, lessThan(const Duration(seconds: 2)));
      expect(previewRequests, hasLength(2));
      expect(scanner.attemptedAnalysisCount, 0);
      expect(scanner.hasCompletedScan, isFalse);
      expect(scanner.isScanning, isFalse);
      previewResponse!.complete({'assets': []});
    },
  );

  test(
    'cancelling a continuous scan stops later rounds and rejects a late thumbnail',
    () async {
      scanner.dispose();
      scanner = PhotoScannerService(
        supportsNativeResources: true,
        continuousPreviewRoundBudget: const Duration(seconds: 1),
      );
      library = List.generate(104, (i) => photo('asset-$i'));
      previewResponse = Completer<Map<String, Object>>();
      final scan = scanner.startContinuousScan();
      for (var i = 0; i < 100 && previewRequests.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(scanner.isScanning, isTrue);
      expect(previewRequests, hasLength(1));
      scanner.cancelScan();
      await scan;
      expect(scanner.wasCancelled, isTrue);
      expect(scanner.isScanning, isFalse);
      previewResponse!.complete({
        'assets': [
          {'assetId': 'asset-0', 'status': 'local', 'thumbnail': preview()},
        ],
      });
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(previewRequests, hasLength(1));
      expect(scanner.attemptedAnalysisCount, 0);
    },
  );

  test(
    'pause waits for continuous preview shutdown before original verification',
    () async {
      previewResponse = Completer<Map<String, Object>>();
      final latePreview = previewResponse!;
      final scan = scanner.startContinuousScan();
      for (var i = 0; i < 100 && previewRequests.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(scanner.isContinuousScanning, isTrue);
      await scanner.pauseContinuousScan();
      expect(scanner.isContinuousScanning, isFalse);
      expect(scanner.scannedAssetCount, 2);
      await scan;
      nativeResults = {
        'first': inspected('first', size: 100),
        'second': inspected('second', size: 200),
      };
      await scanner.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      expect(scanner.knownLibraryBytes, 300);
      expect(resourceRequests, ['first', 'second']);
      latePreview.complete({'assets': []});
    },
  );

  test(
    'pausing continuous previews does not interrupt an unrelated original pass',
    () async {
      resourceResponse = Completer<Map<String, Object>>();
      final verification = scanner.verifyOriginals(
        target: OriginalVerificationTarget.fileSizes,
      );
      for (var i = 0; i < 100 && resourceRequests.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(scanner.isScanning, isTrue);
      expect(scanner.isContinuousScanning, isFalse);
      await scanner.pauseContinuousScan();
      expect(scanner.isScanning, isTrue);
      resourceResponse!.complete(inspected('original', size: 100));
      await verification;
      expect(scanner.knownSizeAssetCount, 2);
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
      expect(processed, inInclusiveRange(8, 500));
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
      expect(previewRequests.length, greaterThan(1));
      expect(scanner.attemptedAnalysisCount, 0);
      expect(scanner.pendingAnalysisCount, 400);
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
    'explicit newest-first native indexing drives previews rather than display-only sorting',
    (tester) async {
      honorRequestedOrder = true;
      library = [
        photo('oldest', created: 1500000000),
        photo('newest', created: 1800000000),
        photo('middle', created: 1700000000),
      ];
      previewResponse = Completer<Map<String, Object>>();
      final scan = scanner.startFullScan();
      for (var i = 0; i < 30 && previewRequests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      final actualOrder = List<String>.of(previewRequests.single);
      scanner.cancelScan();
      await scan;
      previewResponse!.complete({'assets': <Object>[]});
      await tester.pump();
      expect(albumFilters.single['orders'], [
        {'type': 0, 'asc': false},
      ]);
      expect(rangeFilters.single['orders'], [
        {'type': 0, 'asc': false},
      ]);
      expect(actualOrder, ['newest', 'middle', 'oldest']);
    },
  );

  test('visual content candidates precede older metadata-only hints', () async {
    library = [
      photo('metadata-a', created: 1600000000),
      photo('metadata-b', created: 1600000000),
      photo('ordinary', created: 1550000000),
      photo('visual-a', created: 1700000000),
      photo('visual-b', created: 1800000000),
    ];
    nativeResults = {
      'visual-a': inspected('actual-shared-content'),
      'visual-b': inspected('actual-shared-content'),
    };
    await scanner.startFullScan();
    expect(scanner.scanResult.similarGroups.single.assets.length, 2);
    await scanner.verifyOriginals(
      target: OriginalVerificationTarget.exactPhotos,
    );
    expect(resourceRequests.take(2), ['visual-a', 'visual-b']);
    expect(resourceRequests.take(4), [
      'visual-a',
      'visual-b',
      'metadata-a',
      'ordinary',
    ]);
    expect(scanner.scanResult.duplicateGroups.single.assets.length, 2);
  });

  testWidgets(
    'a thousand slow metadata hints cannot hide an ordinary exact pair beyond the round budget',
    (tester) async {
      library = [
        photo('ordinary-a', created: 1700000000),
        photo('ordinary-b', created: 1800000000),
        ...List.generate(1000, (i) => photo('hint-$i', created: 1600000000)),
      ];
      resourceHandler = (id) async {
        if (id.startsWith('ordinary')) {
          return inspected('actual-identical-content');
        }
        await Future<void>.delayed(const Duration(seconds: 4));
        return {'complete': false, 'sizeKnown': false};
      };
      final verification = scanner.verifyOriginals(
        target: OriginalVerificationTarget.exactPhotos,
      );
      for (var i = 0; i < 30 && resourceRequests.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      for (var i = 0; i < 75 && scanner.isScanning; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await verification;
      expect(scanner.lastError, contains('60 秒'));
      expect(resourceRequests.indexOf('ordinary-a'), 3);
      expect(resourceRequests.indexOf('ordinary-b'), 7);
      expect(scanner.verifiedHashAssetCount, 2);
      expect(
        scanner.scanResult.duplicateGroups.single.assets.map((a) => a.id),
        containsAll(['ordinary-a', 'ordinary-b']),
      );
      expect(scanner.pendingHashAssetCount, 1000);
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
