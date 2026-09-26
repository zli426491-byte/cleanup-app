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
    nativeCancellations = [];
    messenger.setMockMethodCallHandler(resources, (call) async {
      final args = call.arguments as Map;
      if (call.method == 'cancelInspections') {
        nativeCancellations.add(args);
        return null;
      }
      final id = args['assetId'] as String;
      resourceRequests.add(id);
      if (resourceResponse != null) return resourceResponse!.future;
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
      expect(resourceRequests, hasLength(5007));
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
      expect(
        scanner.scanResult.allAssets.every(
          (asset) => !asset.sizeKnown && asset.size == 0 && asset.hash == null,
        ),
        isTrue,
      );
      expect(scanner.pendingAnalysisCount, 2);
      expect(scanner.scanResult.duplicateGroups, isEmpty);
      expect(scanner.scanResult.similarGroups, isEmpty);
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
      final scan = scanner.startFullScan();
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
      resourceRequests.clear();
      library = [
        {...photo('first'), 'modifiedDt': 1900000000},
        photo('second'),
      ];
      nativeResults['first'] = inspected('edited-first');
      await scanner.resumeScan();
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
      final scan = subject.startFullScan();
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
    'a local resource operation can take over ten seconds but has a bounded timeout',
    (tester) async {
      library = [photo('video', type: 2)];
      resourceResponse = Completer<Map<String, Object>>();
      final scan = scanner.startFullScan();
      for (var frame = 0; frame < 30 && resourceRequests.isEmpty; frame++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(resourceRequests, ['video']);
      await tester.pump(const Duration(seconds: 15));
      expect(scanner.isScanning, isTrue);
      await tester.pump(const Duration(seconds: 51));
      for (var frame = 0; frame < 20 && scanner.isScanning; frame++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await scan;
      expect(scanner.pendingAnalysisCount, 1);
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
}
