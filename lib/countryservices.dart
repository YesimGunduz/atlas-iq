import 'dart:convert';
import 'package:http/http.dart' as http;

class CountryService {
  static Future<Map<String, dynamic>?> getCountry(String name) async {
    final url =
        Uri.parse('https://restcountries.com/v3.1/name/$name');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]; // ilk sonucu alıyoruz
    } else {
      return null;
    }
  }
}