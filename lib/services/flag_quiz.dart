import 'dart:math';

import 'package:globeinfo/i18n/locale_controller.dart';
import 'package:globeinfo/data/country.dart';

/// Oyunu kurmaya yetecek kadar ülke yoksa atılır.
class NotEnoughCountriesException implements Exception {
  final int count;
  const NotEnoughCountriesException(this.count);

  @override
  String toString() =>
      "Oyun en az 4 ülke gerektiriyor, API'den $count ülke geldi.";
}

/// Soru zorluğu.
///
/// Zorluk bayraktan değil ŞIKLARDAN gelir:
/// - kolay : yanlış şıklar başka bölgelerden
/// - orta  : yanlış şıklar aynı bölgeden
/// - zor   : aynı bölge + bayrağın baskın rengi benzer
enum QuizLevel { easy, medium, hard }

extension QuizLevelInfo on QuizLevel {
  /// Kullanıcıya görünen ad; seçili dile göre değişiyor.
  String get label => switch (this) {
        QuizLevel.easy => S.levelEasy,
        QuizLevel.medium => S.levelMedium,
        QuizLevel.hard => S.levelHard,
      };

  int get points => switch (this) {
        QuizLevel.easy => 1,
        QuizLevel.medium => 2,
        QuizLevel.hard => 3,
      };
}

/// Tek bir soru: doğru cevap, karıştırılmış dört şık ve kademesi.
class QuizQuestion {
  final Country correct;
  final List<Country> options;
  final QuizLevel level;

  const QuizQuestion({
    required this.correct,
    required this.options,
    required this.level,
  });
}

/// Bayrak oyununun kuralları.
///
/// Arayüzden tamamen bağımsız: içinde Widget, renk ya da BuildContext yok.
/// Bu sayede zorluk mantığı test edilebiliyor.
class FlagQuiz {
  static const int questionCount = 10;

  /// Kaçıncı sorudan sonra hangi kademeye geçilir.
  static const int easyUntil = 3; // 1-3
  static const int mediumUntil = 7; // 4-7, sonrası zor

  /// İki bayrak rengi bu RGB uzaklığından yakınsa "benzer" sayılır.
  /// Ölçek 0-441; 90 gözle bakınca karıştırılacak kadar yakın.
  static const double colorThreshold = 90;

  /// Bayrağı olan ülkeler, nüfusa göre çoktan aza sıralı.
  /// Nüfus, "ne kadar tanıdık" için kaba ama işe yarayan bir ölçü.
  final List<Country> pool;

  final Random _random;
  final Set<String> _asked = {};

  FlagQuiz(List<Country> countries, {Random? random})
      : _random = random ?? Random(),
        pool = _preparePool(countries);

  static List<Country> _preparePool(List<Country> countries) {
    final withFlags = countries.where((c) => c.flag.isNotEmpty).toList();

    if (withFlags.length < 4) {
      throw NotEnoughCountriesException(withFlags.length);
    }

    withFlags.sort((a, b) => (b.population ?? 0).compareTo(a.population ?? 0));
    return withFlags;
  }

  /// Bir oyunda toplanabilecek en yüksek puan.
  static int get maxScore {
    var total = 0;
    for (var i = 0; i < questionCount; i++) {
      total += levelFor(i).points;
    }
    return total;
  }

  static QuizLevel levelFor(int index) {
    if (index < easyUntil) return QuizLevel.easy;
    if (index < mediumUntil) return QuizLevel.medium;
    return QuizLevel.hard;
  }

  void reset() => _asked.clear();

  // ---------------------------------------------------------------
  /// [index] numaralı soruyu üretir.
  QuizQuestion questionAt(int index) {
    final level = levelFor(index);
    final tier = tierPool(level);

    // Aynı ülkeyi iki kez sormamaya çalış
    var correct = tier[_random.nextInt(tier.length)];
    for (var i = 0; i < 25; i++) {
      if (!_asked.contains(correct.name)) break;
      correct = tier[_random.nextInt(tier.length)];
    }
    _asked.add(correct.name);

    final options = [correct, ...distractorsFor(correct, level)]
      ..shuffle(_random);

    return QuizQuestion(correct: correct, options: options, level: level);
  }

  /// Kademeye göre doğru cevabın seçileceği alt havuz.
  List<Country> tierPool(QuizLevel level) {
    final n = pool.length;

    // Havuz küçükse kademelere bölmenin anlamı yok.
    if (n < 16) return pool;

    int at(double ratio) => (n * ratio).round().clamp(1, n);

    return switch (level) {
      QuizLevel.easy => pool.sublist(0, at(0.25)),
      QuizLevel.medium => pool.sublist(at(0.20), at(0.60)),
      QuizLevel.hard => pool.sublist(at(0.55)),
    };
  }

  /// Yanlış şıkları kademeye göre seçer. Zorlaştıran şey burası.
  List<Country> distractorsFor(Country correct, QuizLevel level) {
    final others = pool.where((c) => c.name != correct.name).toList();

    List<Country> candidates;

    switch (level) {
      case QuizLevel.easy:
        // Başka bölgelerden -> ayırt etmesi kolay
        candidates = others.where((c) => c.region != correct.region).toList();

      case QuizLevel.medium:
        // Aynı bölgeden -> komşu ülkeler karışır
        candidates = others.where((c) => c.region == correct.region).toList();

      case QuizLevel.hard:
        // Aynı bölge + benzer baskın renk -> asıl zor olan bu
        candidates = others
            .where((c) =>
                c.region == correct.region &&
                colorDistance(c.flagColor, correct.flagColor) < colorThreshold)
            .toList();

        // Yeterli aday yoksa kademe kademe gevşet
        if (candidates.length < 3) {
          candidates = others
              .where((c) =>
                  colorDistance(c.flagColor, correct.flagColor) <
                  colorThreshold)
              .toList();
        }
        if (candidates.length < 3) {
          candidates =
              others.where((c) => c.region == correct.region).toList();
        }
    }

    if (candidates.length < 3) candidates = others;

    candidates.shuffle(_random);

    // Aynı isim iki şıkta çıkmasın
    final picked = <Country>[];
    final usedNames = <String>{correct.name};

    for (final c in candidates) {
      if (picked.length == 3) break;
      if (usedNames.add(c.name)) picked.add(c);
    }

    return picked;
  }

  // ---------------------------------------------------------------
  // RENK BENZERLİĞİ
  // ---------------------------------------------------------------
  /// "#RRGGBB" -> [r, g, b]. Okunamazsa null.
  static List<int>? parseHex(String value) {
    var hex = value.replaceAll("#", "").trim();
    if (hex.length == 3) {
      hex = hex.split("").map((c) => "$c$c").join();
    }
    if (hex.length != 6) return null;

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;

    return [(parsed >> 16) & 0xFF, (parsed >> 8) & 0xFF, parsed & 0xFF];
  }

  /// İki rengin RGB uzayındaki uzaklığı.
  /// Renklerden biri bilinmiyorsa "çok uzak" sayılır.
  static double colorDistance(String a, String b) {
    final ca = parseHex(a);
    final cb = parseHex(b);
    if (ca == null || cb == null) return 9999;

    final dr = (ca[0] - cb[0]).toDouble();
    final dg = (ca[1] - cb[1]).toDouble();
    final db = (ca[2] - cb[2]).toDouble();

    return sqrt(dr * dr + dg * dg + db * db);
  }
}
