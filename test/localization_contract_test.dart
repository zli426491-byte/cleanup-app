import 'package:cleanup_app/l10n/app_localizations.dart';
import 'package:cleanup_app/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final option in LocaleController.languageOptions) {
    test(
      '${option.nativeName}: count samples and safety contracts resolve',
      () {
        final text = lookupAppLocalizations(option.locale);
        for (final count in [0, 1, 2, 100]) {
          final samples = <String>[
            text.homeIndexedCount(count),
            text.homeIndexedCountWithTotal(count, 100),
            text.homePhotoCount(count),
            text.homePhotoCountPartial(count),
            text.homeItemCount(count),
            text.homeVerifiedPhotosPending(count),
            text.homeVerifiedItemsPending(count),
            text.scanExactGroupCount(count),
            text.scanSimilarGroupCount(count),
            text.scanPreviewDeleteCount(count),
            text.scanConfirmDeleteDescription(count),
            text.scanPendingCheckCount(count),
            text.swipeDeletePhotos(count),
            text.swipeConfirmDeleteDescription(count),
            text.swipePartialDeleted(count),
            text.swipeExitDescription(count),
            text.servicePhotosPending(count),
            text.assetSizeBytes(count),
            text.reviewUnseenCount(count),
            text.reviewConfirmCount(count),
            text.swipeResumeReview(count),
            text.swipeBatchSize(count),
            text.scanUnreadableExcluded(count),
            text.homeKnownLibrarySize(count, '12.5 GB'),
            text.homePendingSizes(count),
            text.swipeCheckpointLimit(count),
          ];
          for (final sample in samples) {
            expect(sample.trim(), isNotEmpty);
            expect(sample, isNot(contains(RegExp(r'[{}]|\$'))));
            expect(sample, isNot(contains('\uFFFD')));
          }
        }
        // An original capacity check must never reuse a duplicate-check title.
        expect(text.scanCheckingSizesTitle, isNot(text.scanCheckingExactTitle));
        expect(text.scanCheckingSizesTitle, isNot(text.scanVerifyingTitle));
        expect(text.scanRoundProgress(7, 100), contains('7'));
        expect(text.scanRoundProgress(7, 100), contains('100'));
        expect(text.paywallSubscribeWeekly('USD 4.99'), contains('USD 4.99'));
        expect(text.paywallWeeklyRenewal('USD 4.99'), contains('USD 4.99'));
        expect(text.paywallSubscribeYearly('USD 39.99'), contains('USD 39.99'));
        expect(text.paywallYearlyRenewal('USD 39.99'), contains('USD 39.99'));
      },
    );
  }

  for (final language in ['fr', 'pt']) {
    test('$language zero never reports one photo or item', () {
      final text = lookupAppLocalizations(Locale(language));
      for (final sample in [
        text.homePhotoCount(0),
        text.homeItemCount(0),
        text.homeIndexedCount(0),
        text.homePhotoCountPartial(0),
        text.homeVerifiedPhotosPending(0),
        text.homeVerifiedItemsPending(0),
      ]) {
        expect(sample, contains('0'));
        expect(sample, isNot(contains('1')));
      }
    });
  }

  test('English actions use singular nouns for one selected item', () {
    final text = lookupAppLocalizations(const Locale('en'));
    for (final sample in [
      text.scanPendingCheckCount(1),
      text.scanPreviewDeleteCount(1),
      text.swipeDeletePhotos(1),
      text.scanConfirmDeleteDescription(1),
      text.homeKnownLibrarySize(1, '1 GB'),
    ]) {
      expect(sample, isNot(contains('1 items')));
      expect(sample, isNot(contains('1 photos')));
    }
  });

  for (final language in ['ar', 'he']) {
    test('$language mixed-direction prices and dimensions stay isolated', () {
      final text = lookupAppLocalizations(Locale(language));
      expect(
        text.paywallSubscribeWeekly('USD 4.99'),
        contains('\u2068USD 4.99\u2069'),
      );
      expect(
        text.paywallYearlyRenewal('USD 39.99'),
        contains('\u2068USD 39.99\u2069'),
      );
      expect(text.assetDimensions(1280, 720), '\u20661280 × 720\u2069');
      // Physical left/right gestures must keep their meaning in an RTL UI.
      if (language == 'ar') {
        expect(text.swipeGestureDelete, contains('يسار'));
        expect(text.swipeGestureKeep, contains('يمين'));
      } else {
        expect(text.swipeGestureDelete, contains('שמאלה'));
        expect(text.swipeGestureKeep, contains('ימינה'));
      }
    });
  }
}
