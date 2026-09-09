import 'package:flutter_test/flutter_test.dart';
import 'package:globeinfo/data/country.dart';

/// REST Countries v5'in Kanada icin dondurdugu gercek cevap yapisi.
/// (api.restcountries.com/countries/v5/names.common/Canada)
const canadaV5 = {
  "names": {"common": "Canada", "official": "Canada"},
  "codes": {"alpha_2": "CA"},
  "capitals": [
    {
      "name": "Ottawa",
      "coordinates": {"lat": 45.42, "lng": -75.7},
      "attributes": {"primary": true},
    }
  ],
  "flag": {
    "url_png": "https://flags.restcountries.com/v5/w640/ca.png",
    "emoji": "🇨🇦",
    "colors": {"dominant": "#FF0000"},
  },
  "region": "Americas",
  "population": 41417056,
  "currencies": [
    {"code": "CAD", "name": "Canadian dollar", "symbol": r"$"}
  ],
  "timezones": [
    "UTC-08:00",
    "UTC-07:00",
    "UTC-03:30",
  ],
  "languages": [
    {"name": "English", "native_name": "English", "iso639_1": "en"},
    {"name": "French", "native_name": "français", "iso639_1": "fr"},
  ],
};

void main() {
  group("Country.offsetMinutesOf", () {
    test("tam saatler", () {
      expect(Country.offsetMinutesOf("UTC+03:00"), 180);
      expect(Country.offsetMinutesOf("UTC-05:00"), -300);
    });

    // Bu ayristirma bir kez bozulmustu: yarim saatlik farklari yutuyordu.
    test("yarim saatlik farklar", () {
      expect(Country.offsetMinutesOf("UTC+05:30"), 330);
      expect(Country.offsetMinutesOf("UTC-03:30"), -210);
    });

    test("45 dakikalik fark", () {
      expect(Country.offsetMinutesOf("UTC+05:45"), 345);
    });

    test("isaretsiz ve bos girdi sifir doner", () {
      expect(Country.offsetMinutesOf("UTC"), 0);
      expect(Country.offsetMinutesOf(""), 0);
      expect(Country.offsetMinutesOf("cok garip bir metin"), 0);
    });
  });

  group("Country.fromV5", () {
    final canada = Country.fromV5(Map<String, dynamic>.from(canadaV5));

    test("temel alanlar okunuyor", () {
      expect(canada.name, "Canada");
      expect(canada.region, "Americas");
      expect(canada.alpha2, "CA");
      expect(canada.population, 41417056);
      expect(canada.isValid, isTrue);
    });

    test("baskent capitals[0].name icinden geliyor", () {
      expect(canada.capital, "Ottawa");
    });

    test("para birimi DIZI olarak geliyor", () {
      expect(canada.currencyCode, "CAD");
      expect(canada.currencyName, "Canadian dollar");
    });

    test("diller DIZI olarak geliyor", () {
      expect(canada.languages, ["English", "French"]);
    });

    test("bayrak ve baskin renk", () {
      expect(canada.flag, contains("ca.png"));
      expect(canada.flagColor, "#FF0000");
    });

    test("ilk saat dilimi kullaniliyor", () {
      expect(canada.utcOffsetMinutes, -480); // UTC-08:00
    });

    test("bayrak gelmezse ulke kodundan uretiliyor", () {
      final raw = {
        "names": {"common": "Testonya"},
        "codes": {"alpha_2": "TS"},
      };
      final c = Country.fromV5(raw);
      expect(c.flag, "https://flagcdn.com/w320/ts.png");
    });

    test("isimsiz kayit gecersiz sayiliyor", () {
      final c = Country.fromV5({"region": "Europe"});
      expect(c.isValid, isFalse);
    });

    test("eksik alanlar coke yol acmiyor", () {
      final c = Country.fromV5({
        "names": {"common": "Bosluk"}
      });
      expect(c.capital, "-");
      expect(c.languages, isEmpty);
      expect(c.timezones, isEmpty);
      expect(c.populationText, "-");
      expect(c.currencyText, "-");
    });
  });

  group("gosterim", () {
    test("nufus binlik ayiraci aliyor", () {
      expect(Country(name: "A", population: 84000000).populationText,
          "84.000.000");
      expect(Country(name: "A", population: 999).populationText, "999");
      expect(Country(name: "A", population: 1000).populationText, "1.000");
    });

    test("para birimi metni", () {
      expect(
        Country(name: "A", currencyCode: "EUR", currencyName: "Euro")
            .currencyText,
        "EUR (Euro)",
      );
      expect(Country(name: "A", currencyCode: "XYZ").currencyText, "XYZ");
    });
  });

  group("onbellek", () {
    test("toJson -> fromJson gidip gelince veri korunuyor", () {
      final original = Country.fromV5(Map<String, dynamic>.from(canadaV5));
      final restored = Country.fromJson(original.toJson());

      expect(restored.name, original.name);
      expect(restored.capital, original.capital);
      expect(restored.flag, original.flag);
      expect(restored.flagColor, original.flagColor);
      expect(restored.population, original.population);
      expect(restored.languages, original.languages);
      expect(restored.timezones, original.timezones);
      expect(restored.currencyCode, original.currencyCode);
    });
  });
}
