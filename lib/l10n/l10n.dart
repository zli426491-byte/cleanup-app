import 'package:flutter/widgets.dart';
import 'app_localizations.dart';
import 'service_messages.dart';

/// Standalone review widgets retain the original language without an app shell.
AppLocalizations appStringsOf([BuildContext? context]) =>
    (context == null
        ? null
        : Localizations.of<AppLocalizations>(context, AppLocalizations)) ??
    lookupAppLocalizations(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );

extension CleanupLocalization on BuildContext {
  AppLocalizations get l10n => appStringsOf(this);
  String localizeServiceMessage(String? message) =>
      translateServiceMessage(l10n, message);
}
