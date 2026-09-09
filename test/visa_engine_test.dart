import 'package:flutter_test/flutter_test.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/services/visa_engine.dart';

Country make(String name, {String? visa, String? entry}) =>
    Country(name: name, visa: visa, entry: entry);

void main() {
  final countries = [
    make("Germany", visa: "Visa Required", entry: "Passport Required"),
    make("Georgia", visa: "Visa Free", entry: "ID Only"),
    make("Japan", visa: "Visa Free", entry: "Passport Required"),
    make("India", visa: "E-Visa", entry: "Passport Required"),
    make("Bilinmeyen"), // vize kaydi olmayan ulke
  ];

  group("VisaEngine.filterCountries", () {
    test("filtre verilmezse hepsi doner", () {
      expect(VisaEngine.filterCountries(countries, null, null).length, 5);
    });

    test("vize turune gore suzer", () {
      final result = VisaEngine.filterCountries(countries, "Visa Free", null);
      expect(result.map((c) => c.name), ["Georgia", "Japan"]);
    });

    test("giris belgesine gore suzer", () {
      final result = VisaEngine.filterCountries(countries, null, "ID Only");
      expect(result.map((c) => c.name), ["Georgia"]);
    });

    // Bu ikisi VE ile baglanmali, VEYA ile degil.
    test("iki filtre birlikte daraltir", () {
      final result = VisaEngine.filterCountries(
        countries,
        "Visa Free",
        "Passport Required",
      );
      expect(result.map((c) => c.name), ["Japan"]);
    });

    test("eslesme yoksa bos liste", () {
      final result =
          VisaEngine.filterCountries(countries, "E-Visa", "ID Only");
      expect(result, isEmpty);
    });

    test("vize kaydi olmayan ulke filtreye takilmaz", () {
      final result = VisaEngine.filterCountries(countries, "Visa Free", null);
      expect(result.any((c) => c.name == "Bilinmeyen"), isFalse);
    });

    test("donen liste kopya; kaynagi degistirmiyor", () {
      final result = VisaEngine.filterCountries(countries, null, null);
      result.clear();
      expect(countries.length, 5);
    });
  });

  group("VisaEngine.emptyMessage", () {
    test("etiketleri Turkce gosteriyor", () {
      expect(VisaEngine.emptyMessage("Visa Free", null),
          "Vizesiz için kayıtlı ülke yok");
      expect(VisaEngine.emptyMessage(null, "ID Only"),
          "Kimlikle giriş için kayıtlı ülke yok");
    });

    test("iki filtre birlestiriliyor", () {
      expect(
        VisaEngine.emptyMessage("E-Visa", "Passport Required"),
        "e-Vize + Pasaport gerekli için kayıtlı ülke yok",
      );
    });

    test("filtre yoksa genel mesaj", () {
      expect(VisaEngine.emptyMessage(null, null), "Ülke bulunamadı");
    });
  });
}
