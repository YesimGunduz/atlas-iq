import 'dart:convert';
import 'package:http/http.dart' as http;

class CountryService {
  static Future<Map<String, dynamic>?> getCountry(String name) async {
    try {
      final url = Uri.parse(
        'https://restcountries.com/v3.1/name/$name',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.isNotEmpty ? data[0] : null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String> getTryRate(String currencyCode) async {
    try {
      if (currencyCode == "TRY") {
        return "1 TRY = 1 ₺";
      }

      final response = await http.get(
        Uri.parse(
          'https://open.er-api.com/v6/latest/$currencyCode',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["rates"] != null &&
            data["rates"]["TRY"] != null) {
          final rate = data["rates"]["TRY"];

          return "1 $currencyCode = ${rate.toStringAsFixed(2)} ₺";
        }
      }

      return "-";
    } catch (e) {
      return "-";
    }
  }
}