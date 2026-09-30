# App language support

The active app supports 19 languages: Arabic, English, French, German, Hebrew,
Indonesian, Italian, Japanese, Korean, Polish, Portuguese, Romanian, Russian,
Simplified Chinese, Spanish, Thai, Turkish, Vietnamese, and Traditional Chinese.

The default follows the device's preferred supported language. Unsupported
preferences fall back to English. `zh-TW`, `zh-HK`, and `zh-MO` resolve to
Traditional Chinese; an explicit Chinese script takes precedence over country.
Settings also offers a persisted manual choice and a return to the system setting.
Manual switching updates existing widgets without recreating scan services or
clearing the current tab and photo selections.

Flutter's localization delegates provide system component text and Arabic/Hebrew
right-to-left layout. Photo pixels are not mirrored. Swipe gestures keep their
physical behavior: left marks for deletion and right keeps the photo.

## Translation resources

The current UI uses generated `AppLocalizations` from `lib/l10n/app_*.arb`.
The English file defines typed parameters. `app_zh.arb` is a generator-required
base fallback for Chinese scripts, not an additional user-selectable language.
Services keep scan/subscription state independent of language; `service_messages.dart`
translates their messages at display time, including retained notices and counts.
New service messages must also be added to this mapping and all language files.

Only reachable onboarding, home, settings, photo review, deletion confirmation,
subscription and video-compression flows are covered. Hidden unfinished tools
have not been enabled or advertised by this change.

## iOS resources

Localized app names and permission descriptions are generated into 19
`ios/Runner/*.lproj/InfoPlist.strings` resources and included in the Runner target.
Permission descriptions follow iOS's system/per-app language selection; an
in-app manual language choice does not change iOS's own language setting.
Store listing text and screenshots are a separate localization task.

After editing translations:

```sh
flutter gen-l10n
python scripts/check_localizations.py --write-ios
python scripts/check_localizations.py
flutter analyze
flutter test
```

The resource check verifies complete key coverage, nonempty translations,
parameter names, iOS language declarations, permission text, and build resources.
Tests cover language persistence, system resolution, both Chinese scripts,
live switching, retained messages, RTL, and current screens at small-iPhone/iPad
sizes with enlarged text. Existing scan, purchase and deletion tests remain.

Automated checks do not replace native-speaker review, VoiceOver checks or physical
iPhone/iPad acceptance. In particular, currency and prices are still supplied by
the real StoreKit products; no translated or invented price is substituted.
