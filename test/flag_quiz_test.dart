import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/services/flag_quiz.dart';

Country c(
  String name, {
  String region = "Europe",
  String color = "#FF0000",
  int population = 1000,
  String flag = "https://example.com/f.png",
}) =>
    Country(
      name: name,
      region: region,
      flagColor: color,
      population: population,
      flag: flag,
    );

/// 20 ülkelik yapay havuz: iki bölge, iki renk ailesi.
List<Country> buildPool() => [
      for (var i = 0; i < 10; i++)
        c("Avrupa$i",
            region: "Europe",
            color: i < 5 ? "#FF0000" : "#0000FF",
            population: 1000 - i),
      for (var i = 0; i < 10; i++)
        c("Asya$i",
            region: "Asia",
            color: i < 5 ? "#00FF00" : "#FFFF00",
            population: 500 - i),
    ];

void main() {
  group("kademeler", () {
    test("ilk uc soru kolay, sonraki dort orta, kalani zor", () {
      expect(FlagQuiz.levelFor(0), QuizLevel.easy);
      expect(FlagQuiz.levelFor(2), QuizLevel.easy);
      expect(FlagQuiz.levelFor(3), QuizLevel.medium);
      expect(FlagQuiz.levelFor(6), QuizLevel.medium);
      expect(FlagQuiz.levelFor(7), QuizLevel.hard);
      expect(FlagQuiz.levelFor(9), QuizLevel.hard);
    });

    test("puanlar", () {
      expect(QuizLevel.easy.points, 1);
      expect(QuizLevel.medium.points, 2);
      expect(QuizLevel.hard.points, 3);
    });

    test("en yuksek puan 3x1 + 4x2 + 3x3 = 20", () {
      expect(FlagQuiz.maxScore, 20);
    });
  });

  group("havuz", () {
    test("dortten az ulkeyle kurulamaz", () {
      expect(
        () => FlagQuiz([c("A"), c("B"), c("C")]),
        throwsA(isA<NotEnoughCountriesException>()),
      );
    });

    test("bayragi olmayan ulkeler elenir", () {
      expect(
        () => FlagQuiz([
          c("A"),
          c("B"),
          c("C"),
          c("D", flag: ""),
        ]),
        throwsA(isA<NotEnoughCountriesException>()),
      );
    });

    test("havuz nufusa gore buyukten kucuge siralanir", () {
      final quiz = FlagQuiz([
        c("Kucuk", population: 10),
        c("Buyuk", population: 900),
        c("Orta", population: 400),
        c("Devasa", population: 5000),
      ]);

      expect(
        quiz.pool.map((e) => e.name),
        ["Devasa", "Buyuk", "Orta", "Kucuk"],
      );
    });

    test("havuz kucukse kademelere bolunmez", () {
      final quiz = FlagQuiz([c("A"), c("B"), c("C"), c("D")]);
      expect(quiz.tierPool(QuizLevel.easy).length, 4);
      expect(quiz.tierPool(QuizLevel.hard).length, 4);
    });
  });

  group("soru uretimi", () {
    test("her soruda dort farkli sik var ve dogru cevap iceride", () {
      final quiz = FlagQuiz(buildPool(), random: Random(1));

      for (var i = 0; i < FlagQuiz.questionCount; i++) {
        final q = quiz.questionAt(i);

        expect(q.options.length, 4);
        expect(q.options.map((e) => e.name).toSet().length, 4,
            reason: "ayni ulke iki sikta olmamali");
        expect(q.options.contains(q.correct), isTrue);
        expect(q.level, FlagQuiz.levelFor(i));
      }
    });

    test("bir oyunda ayni ulke iki kez sorulmaz", () {
      final quiz = FlagQuiz(buildPool(), random: Random(7));

      final asked = <String>[];
      for (var i = 0; i < FlagQuiz.questionCount; i++) {
        asked.add(quiz.questionAt(i).correct.name);
      }

      expect(asked.toSet().length, asked.length);
    });

    test("reset sonrasi ulkeler tekrar sorulabilir", () {
      final quiz = FlagQuiz(buildPool(), random: Random(3));
      for (var i = 0; i < FlagQuiz.questionCount; i++) {
        quiz.questionAt(i);
      }
      quiz.reset();
      expect(() => quiz.questionAt(0), returnsNormally);
    });
  });

  group("zorluk gercekten siklardan geliyor", () {
    final quiz = FlagQuiz(buildPool(), random: Random(42));
    final target = c("Avrupa0", region: "Europe", color: "#FF0000");

    test("kolayda yanlis siklar BASKA bolgeden", () {
      final d = quiz.distractorsFor(target, QuizLevel.easy);
      expect(d.length, 3);
      expect(d.every((e) => e.region != "Europe"), isTrue);
    });

    test("ortada yanlis siklar AYNI bolgeden", () {
      final d = quiz.distractorsFor(target, QuizLevel.medium);
      expect(d.length, 3);
      expect(d.every((e) => e.region == "Europe"), isTrue);
    });

    test("zorda ayni bolge VE benzer renk", () {
      final d = quiz.distractorsFor(target, QuizLevel.hard);
      expect(d.length, 3);
      expect(d.every((e) => e.region == "Europe"), isTrue);
      expect(
        d.every((e) =>
            FlagQuiz.colorDistance(e.flagColor, target.flagColor) <
            FlagQuiz.colorThreshold),
        isTrue,
      );
    });

    test("dogru cevap kendi siki olarak tekrar gelmez", () {
      for (final level in QuizLevel.values) {
        final d = quiz.distractorsFor(target, level);
        expect(d.any((e) => e.name == target.name), isFalse);
      }
    });
  });

  group("renk benzerligi", () {
    test("ayni renk sifir uzaklik", () {
      expect(FlagQuiz.colorDistance("#FF0000", "#FF0000"), 0);
    });

    test("cok yakin renkler esigin altinda", () {
      expect(
        FlagQuiz.colorDistance("#FF0000", "#FA0505"),
        lessThan(FlagQuiz.colorThreshold),
      );
    });

    test("zit renkler esigin ustunde", () {
      expect(
        FlagQuiz.colorDistance("#FF0000", "#0000FF"),
        greaterThan(FlagQuiz.colorThreshold),
      );
    });

    test("okunamayan renk cok uzak sayilir", () {
      expect(FlagQuiz.colorDistance("", "#FF0000"), 9999);
      expect(FlagQuiz.colorDistance("mavi", "#FF0000"), 9999);
    });

    test("kisa yazim (#F00) genisletiliyor", () {
      expect(FlagQuiz.parseHex("#F00"), [255, 0, 0]);
      expect(FlagQuiz.parseHex("FF0000"), [255, 0, 0]);
      expect(FlagQuiz.parseHex("yanlis"), isNull);
    });
  });
}
