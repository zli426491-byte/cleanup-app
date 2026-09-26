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
    messenger.setMockMethodCallHandler(channel, (call) async {
      final id = (call.arguments as Map)['id'] as String;
      switch (call.method) {
        case 'fetchEntityProperties':
          return {'id': id, 'type': 1, 'width': 100, 'height': 100};
        case 'getThumb':
          thumbnailRequests.add(id);
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
}
