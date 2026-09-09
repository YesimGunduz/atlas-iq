import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedCountry {
  final String name;
  final String capital;
  final String flag;
  final String continent;

  const SavedCountry({
    required this.name,
    required this.capital,
    required this.flag,
    required this.continent,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "capital": capital,
        "flag": flag,
        "continent": continent,
      };

  factory SavedCountry.fromJson(Map<String, dynamic> json) => SavedCountry(
        name: (json["name"] ?? "").toString(),
        capital: (json["capital"] ?? "-").toString(),
        flag: (json["flag"] ?? "").toString(),
        continent: (json["continent"] ?? "-").toString(),
      );
}

/// Kaydedilen ülkeler. Telefonun diskinde tutulur.
///
/// [ChangeNotifier] olduğu için liste değiştiğinde onu dinleyen ekranlar
/// kendiliğinden yenilenir. Önceden düz bir statik listeydi ve her ekran
/// elle `setState(() {})` çağırmak zorundaydı — biri unutulduğunda ekran
/// eski hâlini göstermeye devam ediyordu.
class SavedData extends ChangeNotifier {
  SavedData._();

  /// Uygulama genelinde tek örnek.
  static final SavedData instance = SavedData._();

  static const String _storageKey = "saved_countries_v1";

  final List<SavedCountry> _countries = [];

  /// Dışarıdan değiştirilemesin diye salt okunur.
  List<SavedCountry> get countries => List.unmodifiable(_countries);

  /// En son kaydedilen en üstte.
  List<SavedCountry> get newestFirst => _countries.reversed.toList();

  int get count => _countries.length;
  bool get isEmpty => _countries.isEmpty;

  bool contains(String name) => _countries.any((e) => e.name == name);

  // ---------------------------------------------------------------
  /// Uygulama açılırken bir kez çağrılır.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _countries
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
                (e) => SavedCountry.fromJson(Map<String, dynamic>.from(e)),
              ),
        );

      notifyListeners();
    } catch (e) {
      debugPrint("SavedData.load ERROR: $e");
    }
  }

  Future<void> add(SavedCountry country) async {
    if (contains(country.name)) return;

    _countries.add(country);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String name) async {
    final removed = _countries.length;
    _countries.removeWhere((e) => e.name == name);

    if (_countries.length == removed) return; // değişmediyse bildirme

    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    if (_countries.isEmpty) return;

    _countries.clear();
    notifyListeners();
    await _persist();
  }

  // ---------------------------------------------------------------
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_countries.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint("SavedData._persist ERROR: $e");
    }
  }
}
