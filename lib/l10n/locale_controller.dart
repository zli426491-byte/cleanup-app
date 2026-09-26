import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleOption {
  final Locale locale;
  final String nativeName;
  const LocaleOption(this.locale, this.nativeName);
}

/// Stores only a deliberate language choice. Null follows device preferences.
class LocaleController extends ChangeNotifier {
  static const preferenceKey = 'app_language';
  static const languageOptions = <LocaleOption>[
    LocaleOption(Locale('ar'), 'العربية'),
    LocaleOption(Locale('en'), 'English'),
    LocaleOption(Locale('fr'), 'Français'),
    LocaleOption(Locale('de'), 'Deutsch'),
    LocaleOption(Locale('he'), 'עברית'),
    LocaleOption(Locale('id'), 'Bahasa Indonesia'),
    LocaleOption(Locale('it'), 'Italiano'),
    LocaleOption(Locale('ja'), '日本語'),
    LocaleOption(Locale('ko'), '한국어'),
    LocaleOption(Locale('pl'), 'Polski'),
    LocaleOption(Locale('pt'), 'Português'),
    LocaleOption(Locale('ro'), 'Română'),
    LocaleOption(Locale('ru'), 'Русский'),
    LocaleOption(
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      '简体中文',
    ),
    LocaleOption(Locale('es'), 'Español'),
    LocaleOption(Locale('th'), 'ไทย'),
    LocaleOption(Locale('tr'), 'Türkçe'),
    LocaleOption(Locale('vi'), 'Tiếng Việt'),
    LocaleOption(
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      '繁體中文',
    ),
  ];

  static final supportedLocales = List<Locale>.unmodifiable(
    languageOptions.map((option) => option.locale),
  );
  SharedPreferences? _preferences;
  Locale? _locale;
  Locale? get locale => _locale;
  String get localeLabel => languageOptions
      .firstWhere(
        (option) => option.locale == _locale,
        orElse: () => languageOptions[1],
      )
      .nativeName;

  LocaleController({Locale? initialLocale}) : _locale = initialLocale;

  static Future<LocaleController> load(SharedPreferences preferences) async {
    final controller = LocaleController();
    controller._preferences = preferences;
    final tag = preferences.getString(preferenceKey);
    for (final option in languageOptions) {
      if (option.locale.toLanguageTag() == tag) {
        controller._locale = option.locale;
      }
    }
    return controller;
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale != null && !supportedLocales.contains(locale)) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported app language');
    }
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    final saved = locale == null
        ? await preferences.remove(preferenceKey)
        : await preferences.setString(preferenceKey, locale.toLanguageTag());
    if (!saved) throw StateError('Could not save the language preference');
    _locale = locale;
    notifyListeners();
  }

  static Locale resolve(List<Locale>? preferred, Iterable<Locale> supported) {
    for (final locale in preferred ?? const <Locale>[]) {
      if (locale.languageCode == 'zh') {
        final script =
            locale.scriptCode ??
            (const ['TW', 'HK', 'MO'].contains(locale.countryCode)
                ? 'Hant'
                : 'Hans');
        return Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: script == 'Hant' ? 'Hant' : 'Hans',
        );
      }
      for (final option in supported) {
        if (option.languageCode == locale.languageCode) return option;
      }
    }
    return const Locale('en');
  }
}
