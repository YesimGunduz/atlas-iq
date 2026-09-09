import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/i18n/locale_controller.dart';

/// Vize / giriş tipine göre ülke filtreleme.
///
/// Alan adları assets/data/countries_database.json ile birebir aynı:
/// `visa` ve `entry`.
class VisaEngine {
  static List<Country> filterCountries(
    List<Country> countries,
    String? visaType,
    String? entryType,
  ) {
    if (visaType == null && entryType == null) {
      return List<Country>.from(countries);
    }

    return countries.where((c) {
      final visaOk = visaType == null || c.visa == visaType;
      final entryOk = entryType == null || c.entry == entryType;
      return visaOk && entryOk;
    }).toList();
  }

  /// Filtreye uyan ülke yoksa kullanıcıya gösterilecek açıklama.
  static String emptyMessage(String? visaType, String? entryType) {
    final parts = <String>[
      if (visaType != null) S.visaLabel(visaType),
      if (entryType != null) S.entryLabel(entryType),
    ];

    if (parts.isEmpty) return S.emptyListTitle;
    return "${parts.join(" + ")} — ${S.emptyFilterNoMatch}";
  }
}
