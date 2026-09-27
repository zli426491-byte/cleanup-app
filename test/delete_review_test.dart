import 'dart:typed_data';
import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/services/photo_scanner_service.dart';
import 'package:cleanup_app/views/scanner/asset_thumbnail.dart';
import 'package:cleanup_app/views/scanner/delete_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';

void main() {
  Uint8List pixel() =>
      Uint8List.fromList(img.encodePng(img.Image(width: 8, height: 12)));
  PhotoAsset photo(String id, {bool invalid = false}) => PhotoAsset(
    id: id,
    width: 8,
    height: 12,
    size: 1024,
    sizeKnown: true,
    createDate: DateTime(2026),
    type: AssetType.image,
    thumbnail: invalid ? Uint8List.fromList([1, 2]) : pixel(),
  );
  Future<void> decode(WidgetTester tester) async {
    final context = tester.element(find.byType(DeleteReview));
    await tester.runAsync(() async {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, context, onError: (_, _) {});
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> mount(
    WidgetTester tester,
    List<PhotoAsset> assets, {
    List<Set<String>> groups = const [],
    Set<String> ready = const {},
    void Function(List<PhotoAsset>?)? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await showDeleteReview(
                  context,
                  assets: assets,
                  reviewGroups: groups,
                  previewReadyIds: ready,
                );
                onResult?.call(result);
              },
              child: const Text('review'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('review'));
    await tester.pumpAndSettle();
    await decode(tester);
  }

  final strings = lookupAppLocalizations(const Locale('en'));
  testWidgets(
    'failed decoded preview is excluded even when caller seeded readiness',
    (tester) async {
      await mount(tester, [photo('bad', invalid: true)], ready: {'bad'});
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, strings.reviewConfirmCount(0)),
            )
            .onPressed,
        isNull,
      );
      expect(find.text(strings.reviewUnseenCount(1)), findsOneWidget);
      await tester.tap(find.byTooltip(strings.reviewRemove));
      await tester.pump();
      expect(find.byKey(const ValueKey('review-bad')), findsNothing);
    },
  );
  testWidgets('remove individual item returns only reviewed retained IDs', (
    tester,
  ) async {
    List<PhotoAsset>? result;
    await mount(tester, [
      photo('a'),
      photo('b'),
    ], onResult: (value) => result = value);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('review-b')),
        matching: find.byTooltip(strings.reviewRemove),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(strings.reviewConfirmCount(1)));
    await tester.pumpAndSettle();
    expect(result!.map((a) => a.id), ['a']);
  });
  testWidgets(
    'all versions requires explicit intent and cancel retains review',
    (tester) async {
      List<PhotoAsset>? result;
      await mount(
        tester,
        [photo('a'), photo('b')],
        groups: [
          {'a', 'b'},
        ],
        onResult: (value) => result = value,
      );
      await tester.tap(find.text(strings.reviewConfirmCount(2)));
      await tester.pumpAndSettle();
      expect(find.text(strings.reviewAllVersions), findsOneWidget);
      await tester.tap(find.text(strings.scanCancel).last);
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(DeleteReview), findsOneWidget);
      await tester.tap(find.text(strings.reviewConfirmCount(2)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.reviewDeleteAllVersions));
      await tester.pumpAndSettle();
      expect(result!.length, 2);
    },
  );
  testWidgets(
    'repeated confirm callback opens only one typed all-version dialog',
    (tester) async {
      List<PhotoAsset>? result;
      await mount(
        tester,
        [photo('a'), photo('b')],
        groups: [
          {'a', 'b'},
        ],
        onResult: (value) => result = value,
      );
      final confirm = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, strings.reviewConfirmCount(2)),
          )
          .onPressed!;
      // Invoke the same pre-rebuild callback twice to reproduce queued taps.
      confirm();
      confirm();
      await tester.pumpAndSettle();
      expect(find.text(strings.reviewAllVersions), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, strings.reviewConfirmCount(2)),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text(strings.reviewDeleteAllVersions));
      await tester.pumpAndSettle();
      expect(result!.map((asset) => asset.id), ['a', 'b']);
      expect(find.byType(DeleteReview), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'late preview failure while all-version confirmation is open blocks return',
    (tester) async {
      List<PhotoAsset>? result;
      await mount(
        tester,
        [photo('a'), photo('b')],
        groups: [
          {'a', 'b'},
        ],
        onResult: (value) => result = value,
      );
      await tester.tap(find.text(strings.reviewConfirmCount(2)));
      await tester.pumpAndSettle();
      tester
          .widget<AssetThumbnail>(find.byType(AssetThumbnail).first)
          .onPreviewReady!(false);
      await tester.pump();
      await tester.tap(find.text(strings.reviewDeleteAllVersions));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(DeleteReview), findsOneWidget);
    },
  );
  for (final locale in AppLocalizations.supportedLocales) {
    for (final size in [const Size(320, 568), const Size(1366, 1024)]) {
      testWidgets(
        '${locale.toLanguageTag()} $size deletion review supports 200 percent text',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: DeleteReview(
                  assets: [
                    photo('layout-ready'),
                    photo('layout-failed', invalid: true),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await decode(tester);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
