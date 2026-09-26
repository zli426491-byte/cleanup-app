import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:cleanup_app/services/photo_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluttercandies/photo_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late PhotoScannerService scanner;
  late List<Map<String, Object>> library;
  late List<String> deletedBySystem;
  late List<List<String>> deletionRequests;
  late PermissionState permission;
  late List<int> rangeEnds;
  Completer<int>? permissionResponse;

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
    'title': 'same-name.jpg',
  };

  setUp(() {
    scanner = PhotoScannerService();
    library = [photo('first'), photo('second')];
    deletedBySystem = [];
    deletionRequests = [];
    rangeEnds = [];
    permission = PermissionState.authorized;
    permissionResponse = null;
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
          return {'data': library.sublist(start, end)};
        case 'deleteWithIds':
          deletionRequests.add(
            List<String>.from((call.arguments as Map)['ids'] as List),
          );
          return deletedBySystem;
        default:
          throw StateError('Unexpected photo API ${call.method}');
      }
    });
  });

  tearDown(() {
    scanner.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'matching metadata is only a review group, never verified duplicates',
    () async {
      await scanner.startFullScan();
      expect(scanner.scanResult.duplicateGroups, isEmpty);
      expect(
        scanner.scanResult.similarGroups.single.assets.map((a) => a.id),
        containsAll(['first', 'second']),
      );
      expect(scanner.scanResult.totalSavingsEstimate, 0);
      expect(scanner.hasCompletedScan, isTrue);
    },
  );

  test('a large library reports exactly the bounded scope', () async {
    library = List.generate(1000, (index) => photo('asset-$index'));
    await scanner.startFullScan();
    expect(scanner.scanResult.allAssets, hasLength(900));
    expect(scanner.availableAssetCount, 1000);
    expect(rangeEnds.last, 900);
    expect(scanner.scanNotice, contains('900 / 1000'));
  });

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
    expect(scanner.scanResult.similarGroups, hasLength(1));
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
}
