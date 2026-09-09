/// Bir ülke.
///
/// API'den gelen ham JSON burada bir kez okunur; uygulamanın geri kalanı
/// `country["populaton"]` gibi sessizce null dönen yazım hatalarına açık
/// haritalarla değil, alanları belli bir nesneyle çalışır.
class Country {
  final String name;
  final String capital;
  final String flag;

  /// Bayrağın baskın rengi, "#RRGGBB". Oyunda benzer bayrakları eşlemek için.
  final String flagColor;

  /// Bayrağın sade dille anlatımı (renkler, düzen, semboller).
  /// API dokümanı bunu birebir "alt metin olarak kullanılabilir" diye
  /// tarif ediyor; ekran okuyucular için kullanıyoruz.
  final String flagDescription;

  final String region;
  final String alpha2;

  final String currencyCode;
  final String currencyName;

  final num? population;
  final List<String> timezones;
  final List<String> languages;

  /// Vize bilgileri yerel veri dosyasından iliştiriliyor, API'den gelmiyor.
  String? visa;
  String? entry;
  String? visaNote;

  Country({
    required this.name,
    this.capital = "-",
    this.flag = "",
    this.flagColor = "",
    this.flagDescription = "",
    this.region = "",
    this.alpha2 = "",
    this.currencyCode = "",
    this.currencyName = "",
    this.population,
    this.timezones = const [],
    this.languages = const [],
    this.visa,
    this.entry,
    this.visaNote,
  });

  bool get isValid => name.isNotEmpty;

  // ===============================================================
  // API (v5) OKUMA
  // ===============================================================
  /// REST Countries v5 kaydını okur.
  ///
  /// Gerçek yapı (doğrulandı):
  ///   names.common          -> "Canada"
  ///   capitals              -> [{name, coordinates, attributes}]
  ///   flag.url_png          -> "https://.../ca.png"
  ///   flag.colors.dominant  -> "#RRGGBB"
  ///   currencies            -> [{code, name, symbol}]   (dizi!)
  ///   languages             -> [{name, native_name, ...}] (dizi!)
  ///   timezones             -> ["UTC-08:00", ...]
  factory Country.fromV5(Map<String, dynamic> raw) {
    final currency = _readCurrency(raw);

    return Country(
      name: _readName(raw),
      capital: _readCapital(raw),
      flag: _readFlag(raw),
      flagColor: _readFlagColor(raw),
      flagDescription: _readFlagDescription(raw),
      region: (raw["region"] ?? "").toString(),
      alpha2: _readAlpha2(raw),
      currencyCode: currency?.code ?? "",
      currencyName: currency?.name ?? "",
      population: raw["population"] is num ? raw["population"] as num : null,
      timezones: _readTimezones(raw),
      languages: _readLanguages(raw),
    );
  }

  static String _readName(Map<String, dynamic> raw) {
    final names = raw["names"];
    if (names is Map && names["common"] != null) {
      return names["common"].toString();
    }
    return "";
  }

  static String _readCapital(Map<String, dynamic> raw) {
    final capitals = raw["capitals"];
    if (capitals is List && capitals.isNotEmpty) {
      final first = capitals.first;
      if (first is Map && first["name"] != null) return first["name"].toString();
      if (first is String) return first;
    }
    return "-";
  }

  static String _readFlag(Map<String, dynamic> raw) {
    final flag = raw["flag"];
    if (flag is Map) {
      final url = flag["url_png"] ?? flag["url_svg"];
      if (url != null) return url.toString();
    }

    // Bayrak gelmediyse ülke kodundan üret
    final code = _readAlpha2(raw);
    if (code.isNotEmpty) {
      return "https://flagcdn.com/w320/${code.toLowerCase()}.png";
    }
    return "";
  }

  static String _readFlagColor(Map<String, dynamic> raw) {
    final flag = raw["flag"];
    if (flag is Map) {
      final colors = flag["colors"];
      if (colors is Map && colors["dominant"] != null) {
        return colors["dominant"].toString();
      }
    }
    return "";
  }

  static String _readFlagDescription(Map<String, dynamic> raw) {
    final flag = raw["flag"];
    if (flag is Map && flag["description"] != null) {
      return flag["description"].toString();
    }
    return "";
  }

  static String _readAlpha2(Map<String, dynamic> raw) {
    final codes = raw["codes"];
    if (codes is Map && codes["alpha_2"] != null) {
      return codes["alpha_2"].toString();
    }
    return "";
  }

  static _Currency? _readCurrency(Map<String, dynamic> raw) {
    final currencies = raw["currencies"];

    // v5: dizi
    if (currencies is List && currencies.isNotEmpty) {
      final first = currencies.first;
      if (first is Map) {
        return _Currency(
          (first["code"] ?? first["iso_4217"] ?? "").toString(),
          (first["name"] ?? "").toString(),
        );
      }
    }

    // Eski biçim: {"CAD": {"name": "..."}}
    if (currencies is Map && currencies.isNotEmpty) {
      final code = currencies.keys.first.toString();
      final detail = currencies[currencies.keys.first];
      if (detail is Map) {
        return _Currency(code, (detail["name"] ?? "").toString());
      }
      return _Currency(code, detail?.toString() ?? "");
    }

    return null;
  }

  static List<String> _readTimezones(Map<String, dynamic> raw) {
    final zones = raw["timezones"];
    if (zones is List) return zones.map((e) => e.toString()).toList();
    if (zones is String) return [zones];
    return const [];
  }

  static List<String> _readLanguages(Map<String, dynamic> raw) {
    final langs = raw["languages"];

    if (langs is List) {
      final out = <String>[];
      for (final item in langs) {
        if (item is String) {
          out.add(item);
        } else if (item is Map) {
          final name = item["name"] ??
              item["english"] ??
              item["native_name"] ??
              item["native"];
          if (name != null) out.add(name.toString());
        }
      }
      return out;
    }

    if (langs is Map) {
      return langs.values.map((e) => e.toString()).toList();
    }

    return const [];
  }

  // ===============================================================
  // ÖNBELLEK
  // ===============================================================
  Map<String, dynamic> toJson() => {
        "name": name,
        "capital": capital,
        "flag": flag,
        "flagColor": flagColor,
        "flagDescription": flagDescription,
        "region": region,
        "alpha2": alpha2,
        "currencyCode": currencyCode,
        "currencyName": currencyName,
        "population": population,
        "timezones": timezones,
        "languages": languages,
      };

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        name: (json["name"] ?? "").toString(),
        capital: (json["capital"] ?? "-").toString(),
        flag: (json["flag"] ?? "").toString(),
        flagColor: (json["flagColor"] ?? "").toString(),
        flagDescription: (json["flagDescription"] ?? "").toString(),
        region: (json["region"] ?? "").toString(),
        alpha2: (json["alpha2"] ?? "").toString(),
        currencyCode: (json["currencyCode"] ?? "").toString(),
        currencyName: (json["currencyName"] ?? "").toString(),
        population: json["population"] is num ? json["population"] as num : null,
        timezones: _stringList(json["timezones"]),
        languages: _stringList(json["languages"]),
      );

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  // ===============================================================
  // GÖSTERİM
  // ===============================================================
  /// 84000000 -> "84.000.000"
  String get populationText {
    final pop = population;
    if (pop == null) return "-";

    final digits = pop.toInt().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(".");
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String get languagesText => languages.isEmpty ? "-" : languages.join(", ");

  /// Ekran okuyucuya verilecek bayrak açıklaması.
  /// API'den açıklama gelmediyse en azından ülke adını söylüyoruz.
  String get flagAltText =>
      flagDescription.isEmpty ? "$name bayrağı" : "$name bayrağı: $flagDescription";

  String get timezonesText => timezones.isEmpty ? "-" : timezones.join(", ");

  String get currencyText {
    if (currencyCode.isEmpty) return "-";
    if (currencyName.isEmpty) return currencyCode;
    return "$currencyCode ($currencyName)";
  }

  // ===============================================================
  // SAAT DİLİMİ
  // ===============================================================
  /// Ülkenin ilk saat diliminin UTC'ye göre farkı, dakika cinsinden.
  int get utcOffsetMinutes =>
      timezones.isEmpty ? 0 : offsetMinutesOf(timezones.first);

  /// "UTC+05:30" -> 330,  "UTC-03:30" -> -210,  "UTC" -> 0
  ///
  /// Yarım saatlik farklar önemli: Kanada'nın UTC-03:30'u, Hindistan'ın
  /// UTC+05:30'u var.
  static int offsetMinutesOf(String timezone) {
    final match =
        RegExp(r'UTC([+-])(\d{1,2})(?::(\d{2}))?').firstMatch(timezone);
    if (match == null) return 0;

    final sign = match.group(1) == "-" ? -1 : 1;
    final hours = int.tryParse(match.group(2) ?? "0") ?? 0;
    final minutes = int.tryParse(match.group(3) ?? "0") ?? 0;

    return sign * (hours * 60 + minutes);
  }

  @override
  String toString() => "Country($name)";
}

class _Currency {
  final String code;
  final String name;
  const _Currency(this.code, this.name);
}
