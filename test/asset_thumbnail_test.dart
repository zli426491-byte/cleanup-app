import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/views/scanner/asset_thumbnail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluttercandies/photo_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final Uint8List pixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aG2kAAAAASUVORK5CYII=',
  );
  late List<String> thumbnailRequests;
  late bool failThumbnail;
  Completer<Uint8List?>? slowResponse;

  PhotoAsset photo(String id) => PhotoAsset(
    id: id,
    width: 100,
    height: 100,
    size: 0,
    createDate: DateTime(2026),
    type: AssetType.image,
  );
  Widget subject(String id, {int size = 220}) => MaterialApp(
    home: AssetThumbnail(asset: photo(id), previewSize: size),
  );

  setUp(() {
    thumbnailRequests = [];
    failThumbnail = false;
    slowResponse = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      final id = (call.arguments as Map)['id'] as String;
      switch (call.method) {
        case 'fetchEntityProperties':
          return {'id': id, 'type': 1, 'width': 100, 'height': 100};
        case 'getThumb':
          thumbnailRequests.add(id);
          if (id.endsWith('-slow') && slowResponse != null) {
            return slowResponse!.future;
          }
          return failThumbnail ? null : pixel;
        default:
          throw StateError('Unexpected photo API ${call.method}');
      }
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('reused card loads the new asset and requested preview size', (
    tester,
  ) async {
    await tester.pumpWidget(subject('card-first'));
    await tester.pumpAndSettle();
    expect(thumbnailRequests, ['card-first']);
    await tester.pumpWidget(subject('card-next', size: 800));
    await tester.pumpAndSettle();
    expect(thumbnailRequests, ['card-first', 'card-next']);
    expect(find.byType(Image), findsOneWidget);
    await tester.pumpWidget(subject('card-next', size: 220));
    await tester.pumpAndSettle();
    expect(thumbnailRequests, ['card-first', 'card-next', 'card-next']);
  });

  testWidgets(
    'failed thumbnails are retried on reopening instead of cached forever',
    (tester) async {
      failThumbnail = true;
      await tester.pumpWidget(subject('retry-card'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      await tester.pumpWidget(const SizedBox());
      failThumbnail = false;
      await tester.pumpWidget(subject('retry-card'));
      await tester.pumpAndSettle();
      expect(thumbnailRequests, ['retry-card', 'retry-card']);
      expect(find.byType(Image), findsOneWidget);
    },
  );

  testWidgets(
    'slow cloud preview still displays after the former 1.2 second deadline',
    (tester) async {
      slowResponse = Completer<Uint8List?>();
      await tester.pumpWidget(subject('cloud-slow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2000));
      slowResponse!.complete(pixel);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'failed preview retries on the current screen without reopening',
    (tester) async {
      failThumbnail = true;
      await tester.pumpWidget(subject('onscreen-retry'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      failThumbnail = false;
      await tester.tap(find.byTooltip('重新載入預覽'));
      await tester.pumpAndSettle();
      expect(thumbnailRequests, ['onscreen-retry', 'onscreen-retry']);
      expect(find.byType(Image), findsOneWidget);
    },
  );

  testWidgets('a late request cannot replace the newly selected asset', (
    tester,
  ) async {
    slowResponse = Completer<Uint8List?>();
    await tester.pumpWidget(subject('previous-slow'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(subject('current-fast'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    // The old native response is deliberately unusable. It must never be
    // installed into the new asset's Image or trigger that widget's retry.
    slowResponse!.complete(Uint8List.fromList([0]));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byTooltip('重新載入預覽'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
