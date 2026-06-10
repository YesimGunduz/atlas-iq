class VisaEngine {
  static final Map<String, String> visaData = {
    "JP": "Visa Free",
    "DE": "Visa Free",
    "US": "Visa Required",
    "FR": "Visa Free",
    "GB": "Visa Required",
    "IT": "Visa Free",
    "ES": "Visa Free",
  };

  static String getVisaType(String code) {
    return visaData[code] ?? "Visa Required";
  }

  static List<Map<String, dynamic>> filterCountries(
    List<Map<String, dynamic>> countries,
    String? visaType,
    String? entryType,
  ) {
    return countries.where((c) {
      final code = c["code"];

      final visa = getVisaType(code);
      final entry = c["entryType"];

      final visaOk = visaType == null || visa == visaType;
      final entryOk = entryType == null || entry == entryType;

      return visaOk && entryOk;
    }).toList();
  }
}