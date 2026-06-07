import 'package:flutter/material.dart';

class SavedCountry {
  final String name;
  final String capital;
  final String flag;
  final String continent;

  SavedCountry({
    required this.name,
    required this.capital,
    required this.flag,
    required this.continent,
  });
}

class SavedData {
  static List<SavedCountry> savedCountries = [];
}