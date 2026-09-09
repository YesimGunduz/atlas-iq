import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/i18n/locale_controller.dart';

/// assets/data/countries_database.json içindeki vize kurallarını yükler.
///
/// Dosya yapısı:
/// {
///   "passport": "...", "updated": "2026-09", "disclaimer": "...",
///   "countries": [
///     {"country": "Germany", "visa": "Visa Required",
///      "entry": "Passport Required", "note": "Schengen vizesi"}
///   ]
/// }
///
/// Eski düz dizi biçimi de okunabiliyor.
class VisaDatabase {
  static const String assetPath = 'assets/data/countries_database.json';

  static final Map<String, Map<String, dynamic>> _byCountry = {};

  static String _passportTr = "";
  static String _passportEn = "";
  static String _disclaimerTr = "";
  static String _disclaimerEn = "";

  static String updated = "";

  /// Seçili dile göre. İngilizce karşılık yoksa Türkçesine düşer.
  static String get passport =>
      LocaleController.instance.locale == AppLocale.en && _passportEn.isNotEmpty
          ? _passportEn
          : _passportTr;

  static String get disclaimer =>
      LocaleController.instance.locale == AppLocale.en &&
              _disclaimerEn.isNotEmpty
          ? _disclaimerEn
          : _disclaimerTr;

  static bool get isLoaded => _byCountry.isNotEmpty;
  static int get recordCount => _byCountry.length;

  static Future<void> load() async {
    if (isLoaded) return;

    final String raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    List<dynamic> list;

    if (decoded is Map) {
      _passportTr = (decoded["passport"] ?? "").toString();
      _passportEn = (decoded["passport_en"] ?? "").toString();
      _disclaimerTr = (decoded["disclaimer"] ?? "").toString();
      _disclaimerEn = (decoded["disclaimer_en"] ?? "").toString();
      updated = (decoded["updated"] ?? "").toString();
      list = decoded["countries"] is List ? decoded["countries"] as List : [];
    } else if (decoded is List) {
      list = decoded;
    } else {
      return;
    }

    for (final item in list) {
      if (item is! Map) continue;

      final name = item["country"]?.toString();
      if (name == null || name.isEmpty) continue;

      _byCountry[name.toLowerCase()] = Map<String, dynamic>.from(item);
    }
  }

  static Map<String, dynamic>? findByCountry(String name) =>
      _byCountry[name.trim().toLowerCase()];

  static String? visaOf(String name) => findByCountry(name)?["visa"]?.toString();

  static String? entryOf(String name) =>
      findByCountry(name)?["entry"]?.toString();

  static String? noteOf(String name) {
    final note = findByCountry(name)?["note"]?.toString();
    return (note == null || note.isEmpty) ? null : note;
  }

  /// Ülke nesnelerine vize bilgilerini iliştirir.
  /// Vize verisi olmayan ülkelerde alanlar null kalır.
  static List<Country> attachTo(List<Country> countries) {
    for (final country in countries) {
      final record = findByCountry(country.name);
      country.visa = record?["visa"]?.toString();
      country.entry = record?["entry"]?.toString();
      country.visaNote = record?["note"]?.toString();
    }
    return countries;
  }
}
