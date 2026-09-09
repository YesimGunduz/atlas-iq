import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/services/country_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oyunu kurmaya yetecek kadar ülke gelmediğinde atılır.
class _NotEnoughCountries implements Exception {
  final int count;
  const _NotEnoughCountries(this.count);

  @override
  String toString() =>
      "Oyun en az 4 ülke gerektiriyor, API'den $count ülke geldi.";
}

/// Soru zorluğu.
///
/// Zorluk bayraktan değil ŞIKLARDAN gelir:
/// - kolay : yanlış şıklar başka kıtalardan
/// - orta  : yanlış şıklar aynı bölgeden
/// - zor   : aynı bölge + bayrağın baskın rengi benzer
enum _Level { easy, medium, hard }

extension _LevelInfo on _Level {
  String get label => switch (this) {
        _Level.easy => "Kolay",
        _Level.medium => "Orta",
        _Level.hard => "Zor",
      };

  Color get color => switch (this) {
        _Level.easy => const Color(0xFF2ED573),
        _Level.medium => const Color(0xFFFFA502),
        _Level.hard => const Color(0xFFFF4757),
      };

  int get points => switch (this) {
        _Level.easy => 1,
        _Level.medium => 2,
        _Level.hard => 3,
      };
}

/// Bayrak bilme oyunu: bayrağı gösterir, 4 şıktan doğru ülkeyi sorar.
class FlagGamePage extends StatefulWidget {
  const FlagGamePage({super.key});

  @override
  State<FlagGamePage> createState() => _FlagGamePageState();
}

class _FlagGamePageState extends State<FlagGamePage> {
  static const int questionCount = 10;
  static const String _bestKey = "flag_game_best_points";

  /// Kaçıncı sorudan sonra hangi kademeye geçilir.
  static const int _easyUntil = 3; // 1-3
  static const int _mediumUntil = 7; // 4-7, sonrası zor

  /// İki bayrak rengi bu RGB uzaklığından yakınsa "benzer" sayılır.
  /// Ölçek 0-441 arası; 90 gözle bakınca karıştırılacak kadar yakın.
  static const double _colorThreshold = 90;

  final Random _random = Random();

  /// Bayrağı olan ülkeler, nüfusa göre çoktan aza sıralı.
  List<Country> _byPopulation = [];

  bool _loading = true;
  String? _error;

  int _index = 0;
  int _score = 0; // puan
  int _correctCount = 0; // doğru sayısı
  int _streak = 0;
  int _bestStreak = 0;
  int _best = 0; // rekor (puan)

  final Set<String> _asked = {};

  Country? _correct;
  List<Country> _options = [];
  _Level _level = _Level.easy;

  String? _selected;
  bool _finished = false;
  bool _isNewRecord = false;

  Timer? _nextTimer;

  /// Bir oyunda toplanabilecek en yüksek puan.
  static int get maxScore {
    var total = 0;
    for (var i = 0; i < questionCount; i++) {
      total += _levelFor(i).points;
    }
    return total;
  }

  static _Level _levelFor(int index) {
    if (index < _easyUntil) return _Level.easy;
    if (index < _mediumUntil) return _Level.medium;
    return _Level.hard;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    super.dispose();
  }

  // ===============================================================
  // VERİ
  // ===============================================================
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final best = prefs.getInt(_bestKey) ?? 0;

      final countries = await CountryService.getAllCountries();

      final withFlags = countries.where((c) => c.flag.isNotEmpty).toList();

      if (withFlags.length < 4) throw _NotEnoughCountries(withFlags.length);

      // Nüfusu yüksek ülke = daha tanıdık ülke. Kademeleri buna göre kuruyoruz.
      withFlags.sort(
        (a, b) => (b.population ?? 0).compareTo(a.population ?? 0),
      );

      if (!mounted) return;

      setState(() {
        _byPopulation = withFlags;
        _best = best;
        _loading = false;
      });

      _startGame();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "$e";
      });
    }
  }

  // ===============================================================
  // SORU KURMA
  // ===============================================================
  /// Kademeye göre doğru cevabın seçileceği alt havuz.
  List<Country> _tierPool(_Level level) {
    final n = _byPopulation.length;

    // Havuz küçükse kademelere bölmenin anlamı yok.
    if (n < 16) return _byPopulation;

    int at(double ratio) => (n * ratio).round().clamp(1, n);

    return switch (level) {
      _Level.easy => _byPopulation.sublist(0, at(0.25)),
      _Level.medium => _byPopulation.sublist(at(0.20), at(0.60)),
      _Level.hard => _byPopulation.sublist(at(0.55)),
    };
  }

  /// Yanlış şıkları kademeye göre seç. Zorlaştıran şey burası.
  List<Country> _pickDistractors(Country correct, _Level level) {
    final correctName = correct.name;
    final region = correct.region;
    final color = correct.flagColor;

    final others =
        _byPopulation.where((c) => c.name != correctName).toList();

    List<Country> candidates;

    switch (level) {
      case _Level.easy:
        // Başka bölgelerden -> ayırt etmesi kolay
        candidates = others.where((c) => c.region != region).toList();

      case _Level.medium:
        // Aynı bölgeden -> komşu ülkeler karışır
        candidates = others.where((c) => c.region == region).toList();

      case _Level.hard:
        // Aynı bölge + benzer baskın renk -> asıl zor olan bu
        candidates = others
            .where((c) =>
                c.region == region &&
                _colorDistance(c.flagColor, color) < _colorThreshold)
            .toList();

        // Yeterli aday yoksa kademe kademe gevşet
        if (candidates.length < 3) {
          candidates = others
              .where((c) =>
                  _colorDistance(c.flagColor, color) < _colorThreshold)
              .toList();
        }
        if (candidates.length < 3) {
          candidates = others.where((c) => c.region == region).toList();
        }
    }

    if (candidates.length < 3) candidates = others;

    candidates.shuffle(_random);

    // Aynı isim iki şıkta çıkmasın
    final picked = <Country>[];
    final usedNames = <String>{correctName};

    for (final c in candidates) {
      if (picked.length == 3) break;
      if (usedNames.add(c.name)) picked.add(c);
    }

    return picked;
  }

  void _nextQuestion() {
    final level = _levelFor(_index);
    final pool = _tierPool(level);

    // Aynı ülkeyi iki kez sormamaya çalış
    Country correct = pool[_random.nextInt(pool.length)];
    for (var i = 0; i < 25; i++) {
      if (!_asked.contains(correct.name)) break;
      correct = pool[_random.nextInt(pool.length)];
    }
    _asked.add(correct.name);

    final options = [correct, ..._pickDistractors(correct, level)];
    options.shuffle(_random);

    setState(() {
      _level = level;
      _correct = correct;
      _options = options;
      _selected = null;
    });
  }

  // ===============================================================
  // RENK BENZERLİĞİ
  // ===============================================================
  /// "#RRGGBB" -> [r, g, b]. Okunamazsa null.
  static List<int>? _parseHex(String value) {
    var hex = value.replaceAll("#", "").trim();
    if (hex.length == 3) {
      hex = hex.split("").map((c) => "$c$c").join();
    }
    if (hex.length != 6) return null;

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return null;

    return [(parsed >> 16) & 0xFF, (parsed >> 8) & 0xFF, parsed & 0xFF];
  }

  /// İki rengin RGB uzayındaki uzaklığı. Renk bilinmiyorsa "çok uzak" sayılır.
  static double _colorDistance(String a, String b) {
    final ca = _parseHex(a);
    final cb = _parseHex(b);
    if (ca == null || cb == null) return 9999;

    final dr = (ca[0] - cb[0]).toDouble();
    final dg = (ca[1] - cb[1]).toDouble();
    final db = (ca[2] - cb[2]).toDouble();

    return sqrt(dr * dr + dg * dg + db * db);
  }

  // ===============================================================
  // OYUN AKIŞI
  // ===============================================================
  void _startGame() {
    setState(() {
      _index = 0;
      _score = 0;
      _correctCount = 0;
      _streak = 0;
      _bestStreak = 0;
      _finished = false;
      _isNewRecord = false;
      _asked.clear();
    });
    _nextQuestion();
  }

  void _answer(Country option) {
    if (_selected != null) return;

    final name = option.name;
    final correctName = _correct!.name;
    final isRight = name == correctName;

    setState(() {
      _selected = name;
      if (isRight) {
        _correctCount++;
        _score += _level.points;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _streak = 0;
      }
    });

    _nextTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;

      if (_index + 1 >= questionCount) {
        _finish();
      } else {
        setState(() => _index++);
        _nextQuestion();
      }
    });
  }

  Future<void> _finish() async {
    final beatRecord = _score > _best;

    setState(() {
      _finished = true;
      _isNewRecord = beatRecord;
    });

    if (beatRecord) {
      setState(() => _best = _score);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_bestKey, _score);
      } catch (_) {
        // rekor kaydedilemezse oyun yine de çalışsın
      }
    }
  }

  // ===============================================================
  // ŞIK GÖRÜNÜMÜ
  // ===============================================================
  Color _optionColor(String name) {
    if (_selected == null) return const Color(0xFF162440);
    final correctName = _correct!.name;
    if (name == correctName) return const Color(0xFF1B5E3F);
    if (name == _selected) return const Color(0xFF6B2130);
    return const Color(0xFF162440);
  }

  Color _optionBorder(String name) {
    if (_selected == null) return const Color(0xFF223B5E);
    final correctName = _correct!.name;
    if (name == correctName) return const Color(0xFF2ED573);
    if (name == _selected) return const Color(0xFFFF4757);
    return const Color(0xFF223B5E);
  }

  IconData? _optionIcon(String name) {
    if (_selected == null) return null;
    final correctName = _correct!.name;
    if (name == correctName) return Icons.check_circle;
    if (name == _selected) return Icons.cancel;
    return null;
  }

  // ===============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        iconTheme: const IconThemeData(color: Color(0xFF8FB3DA)),
        title: const Text(
          "Bayrak Oyunu",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: Color(0xFFFFA502), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "$_best",
                    style: const TextStyle(
                      color: Color(0xFFFFA502),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    if (_error != null) return _buildError();
    if (_finished) return _buildResult();

    if (_correct == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    return _buildQuestion();
  }

  // ---------------------------------------------------------------
  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Color(0xFF7A9CC4), size: 40),
            const SizedBox(height: 12),
            const Text(
              "Oyun başlatılamadı",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8AA4C2), fontSize: 13),
            ),
            if (CountryService.isUsingDemoKey) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFA502),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFA502)),
                ),
                child: const Text(
                  "Demo API anahtarı yalnızca 1 ülke (Kanada) döndürüyor.\n"
                  "Oyun için en az 4 ülke gerekiyor.\n\n"
                  "restcountries.com/sign-up adresinden ücretsiz anahtar al, "
                  "sonra uygulamayı şöyle başlat:\n\n"
                  "flutter run --dart-define=RC_API_KEY=anahtarin",
                  style: TextStyle(
                    color: Color(0xFFFFA502),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text("Tekrar dene"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  Widget _buildQuestion() {
    final flag = _correct!.flag;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "Soru ${_index + 1} / $questionCount",
                      style: const TextStyle(
                        color: Color(0xFF8AA4C2),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _levelBadge(),
                    const Spacer(),
                    if (_streak >= 2) ...[
                      const Icon(Icons.local_fire_department,
                          color: Color(0xFFFFA502), size: 16),
                      const SizedBox(width: 3),
                      Text(
                        "$_streak",
                        style: const TextStyle(
                          color: Color(0xFFFFA502),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      "$_score puan",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (_index + 1) / questionCount),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF162440),
                      valueColor: AlwaysStoppedAnimation(_level.color),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(flag),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF122038),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF223B5E)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  flag,
                  height: 140,
                  // Bilerek semanticLabel yok: ülke adı cevabın kendisi.
                  excludeFromSemantics: true,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 140,
                          width: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3B82F6),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 140,
                    width: 200,
                    child: Icon(Icons.flag,
                        size: 60, color: Color(0xFF7A9CC4)),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Bu bayrak hangi ülkeye ait?",
            style: TextStyle(color: Color(0xFF8AA4C2), fontSize: 14),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(children: _options.map(_buildOption).toList()),
          ),
        ],
      ),
    );
  }

  Widget _levelBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _level.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _level.color),
      ),
      child: Text(
        "${_level.label} · ${_level.points}p",
        style: TextStyle(
          color: _level.color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOption(Country option) {
    final name = option.name;
    final icon = _optionIcon(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selected == null ? () => _answer(option) : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _optionColor(name),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _optionBorder(name), width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: icon == Icons.check_circle
                        ? const Color(0xFF2ED573)
                        : const Color(0xFFFF4757),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  Widget _buildResult() {
    String message;
    if (_correctCount == questionCount) {
      message = "Kusursuz! Zor soruları da bildin.";
    } else if (_score >= maxScore * 0.7) {
      message = "İyi iş, coğrafyan sağlam.";
    } else if (_score >= maxScore * 0.4) {
      message = "Fena değil, zor sorular biraz zorladı.";
    } else {
      message = "Bayraklara biraz daha bakmak lazım.";
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Icon(
                _isNewRecord ? Icons.emoji_events : Icons.flag_circle,
                size: 80,
                color: _isNewRecord
                    ? const Color(0xFFFFA502)
                    : const Color(0xFF3B82F6),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "$_score / $maxScore puan",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "$_correctCount / $questionCount doğru",
              style: const TextStyle(color: Color(0xFF8AA4C2), fontSize: 15),
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8AA4C2), fontSize: 14),
            ),

            if (_isNewRecord) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFA502),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFA502)),
                ),
                child: const Text(
                  "Yeni rekor!",
                  style: TextStyle(
                    color: Color(0xFFFFA502),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _resultStat("En uzun seri", "$_bestStreak"),
                const SizedBox(width: 32),
                _resultStat("Rekor", "$_best"),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _startGame,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar oyna"),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Ana sayfaya dön",
                  style: TextStyle(color: Color(0xFF8AA4C2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8AA4C2), fontSize: 12),
        ),
      ],
    );
  }
}
