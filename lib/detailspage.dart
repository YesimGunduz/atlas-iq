import 'package:flutter/material.dart';
import 'countryservices.dart';

class CountryDetailPage extends StatefulWidget {
  final String query;

  const CountryDetailPage({super.key, required this.query});

  @override
  State<CountryDetailPage> createState() => _CountryDetailPageState();
}

class _CountryDetailPageState extends State<CountryDetailPage> {
  Map<String, dynamic>? country;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCountry();
  }

  Future<void> fetchCountry() async {
    final data = await CountryService.getCountry(widget.query);

    setState(() {
      country = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162440),
        title: Text(widget.query),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : country == null
              ? const Center(
                  child: Text(
                    "Country not found",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162440),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country!['flag'] ?? '',
                          style: const TextStyle(fontSize: 50),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          country!['name']['common'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        info("Capital",
                            country!['capital']?[0] ?? '-'),
                        info("Region", country!['region'] ?? '-'),
                        info("Population",
                            country!['population'].toString()),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: Color(0xFF7A9CC4))),
          Text(value,
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}