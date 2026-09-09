import 'package:flutter_test/flutter_test.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/i18n/locale_controller.dart';
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
    // Varsayilan dil Turkce oldugu icin Turkce etiketler bekleniyor.
    test("etiketleri secili dilde gosteriyor", () {
      expect(VisaEngine.emptyMessage("Visa Free", null),
          contains("Vizesiz"));
      expect(VisaEngine.emptyMessage(null, "ID Only"),
          contains("Kimlikle giriş"));
    });

    test("iki filtre birlestiriliyor", () {
      final message =
          VisaEngine.emptyMessage("E-Visa", "Passport Required");
      expect(message, contains("e-Vize"));
      expect(message, contains("Pasaport gerekli"));
      expect(message, contains("+"));
    });

    test("filtre yoksa genel mesaj", () {
      expect(VisaEngine.emptyMessage(null, null), isNotEmpty);
    });

    test("dil degisince etiketler de degisiyor", () async {
      await LocaleController.instance.setLocale(AppLocale.en);
      expect(VisaEngine.emptyMessage("Visa Free", null),
          contains("Visa Free"));

      await LocaleController.instance.setLocale(AppLocale.tr);
      expect(VisaEngine.emptyMessage("Visa Free", null),
          contains("Vizesiz"));
    });
  });
}
