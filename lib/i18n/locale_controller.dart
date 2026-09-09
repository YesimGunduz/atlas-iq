import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:globeinfo/i18n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale {
  tr("tr", "Türkçe", "TR"),
  en("en", "English", "EN");

  final String code;
  final String nativeName;

  /// Düğmede görünen kısa etiket.
  final String short;

  const AppLocale(this.code, this.nativeName, this.short);

  static AppLocale fromCode(String? code) =>
      AppLocale.values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLocale.tr,
      );
}

/// Seçili dili tutar ve diske kaydeder.
///
/// [ChangeNotifier] olduğu için dil değişince onu dinleyen [MaterialApp]
/// yeniden kuruluyor ve bütün ekranlar yeni dille çiziliyor.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const String _storageKey = "app_locale";

  AppLocale _locale = AppLocale.tr;
  AppLocale get locale => _locale;

  /// Seçili dilin metin sözlüğü.
  AppStrings get strings =>
      _locale == AppLocale.tr ? const TrStrings() : const EnStrings();

  Locale get flutterLocale => Locale(_locale.code);

  /// Uygulama açılırken bir kez çağrılır.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved == null) return;

      final restored = AppLocale.fromCode(saved);
      if (restored == _locale) return;

      _locale = restored;
      notifyListeners();
    } catch (e) {
      debugPrint("LocaleController.load ERROR: $e");
    }
  }

  Future<void> setLocale(AppLocale value) async {
    if (value == _locale) return;

    _locale = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, value.code);
    } catch (e) {
      debugPrint("LocaleController.setLocale ERROR: $e");
    }
  }
}

/// Metinlere kısayol: `S.rowCapital` gibi kullanılıyor.
///
/// Dil değiştiğinde [MaterialApp] baştan kurulduğu için bütün ekranlar
/// bu getter'ı yeniden okuyor.
AppStrings get S => LocaleController.instance.strings;
