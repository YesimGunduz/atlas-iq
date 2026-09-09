import 'package:globeinfo/data/labels.dart';

/// Vize / giriş tipine göre ülke filtreleme.
///
/// Alan adları assets/data/countries_database.json ile birebir aynı:
/// `visa` ve `entry`.
class VisaEngine {
  static List<Map<String, dynamic>> filterCountries(
    List<Map<String, dynamic>> countries,
    String? visaType,
    String? entryType,
  ) {
    if (visaType == null && entryType == null) {
      return List<Map<String, dynamic>>.from(countries);
    }

    return countries.where((c) {
      final visa = c["visa"];
      final entry = c["entry"];

      final visaOk = visaType == null || visa == visaType;
      final entryOk = entryType == null || entry == entryType;

      return visaOk && entryOk;
    }).toList();
  }

  /// Filtreye uyan ülke yoksa kullanıcıya gösterilecek açıklama.
  static String emptyMessage(String? visaType, String? entryType) {
    final parts = <String>[
      if (visaType != null) Labels.visa(visaType),
      if (entryType != null) Labels.entry(entryType),
    ];

    if (parts.isEmpty) return "Ülke bulunamadı";
    return "${parts.join(" + ")} için kayıtlı ülke yok";
  }
}
