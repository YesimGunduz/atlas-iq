import 'package:flutter/material.dart';
import 'visa_engine.dart';

class FilterResultPage extends StatefulWidget {
  final List<Map<String, dynamic>> allCountries;
  final Map filters;

  const FilterResultPage({
    super.key,
    required this.allCountries,
    required this.filters,
  });

  @override
  State<FilterResultPage> createState() => _FilterResultPageState();
}

class _FilterResultPageState extends State<FilterResultPage> {
  late List<Map<String, dynamic>> filtered;

 @override
void initState() {
  super.initState();

  final visa = widget.filters["visa"];
  final entry = widget.filters["entry"];

  filtered = VisaEngine.filterCountries(
  widget.allCountries,
  widget.filters["visa"],
  widget.filters["entry"],
);
  print("ALL COUNTRIES: ${widget.allCountries.length}");
  print("FILTERED: ${filtered.length}");
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
       iconTheme: const IconThemeData(color: Color(0xFF8FB3DA)),
        backgroundColor: const Color(0xFF0A1628),
       title: const Text(
  "Results",
  style: TextStyle(
    color: Color(0xFF8FB3DA),
  ),
),
      ),
      body: filtered.isEmpty
          ? const Center(child: Text("No countries found"))
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final c = filtered[index];

                return ListTile(
                  title: Text(c["name"] ?? "",
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(c["code"] ?? "",
                      style: const TextStyle(color: Colors.white54)),
                );
              },
            ),
    );
  }
}