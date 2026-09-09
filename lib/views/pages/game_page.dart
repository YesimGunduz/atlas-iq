import 'dart:async';

import 'package:flutter/material.dart';
import 'package:globeinfo/services/country_services.dart';
import 'package:globeinfo/services/flag_quiz.dart';
import 'package:globeinfo/theme/app_colors.dart';
import 'package:globeinfo/views/widgets/quiz_option_tile.dart';
import 'package:globeinfo/views/widgets/quiz_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bayrak bilme oyunu.
///
/// Oyunun kuralları (kademeler, şık seçimi, renk benzerliği) burada değil;
/// [FlagQuiz] içinde. Bu dosya yalnızca ekranı çiziyor ve skoru tutuyor.
class FlagGamePage extends StatefulWidget {
  const FlagGamePage({super.key});

  @override
  State<FlagGamePage> createState() => _FlagGamePageState();
}

class _FlagGamePageState extends State<FlagGamePage> {
  static const String _bestKey = "flag_game_best_points";

  FlagQuiz? _quiz;
  QuizQuestion? _question;

  bool _loading = true;
  String? _error;

  int _index = 0;
  int _score = 0;
  int _correctCount = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _best = 0;

  String? _selected;
  bool _finished = false;
  bool _isNewRecord = false;

  Timer? _nextTimer;

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
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final best = prefs.getInt(_bestKey) ?? 0;

      final countries = await CountryService.getAllCountries();
      final quiz = FlagQuiz(countries);

      if (!mounted) return;

      setState(() {
        _quiz = quiz;
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

  void _startGame() {
    _quiz?.reset();

    setState(() {
      _index = 0;
      _score = 0;
      _correctCount = 0;
      _streak = 0;
      _bestStreak = 0;
      _finished = false;
      _isNewRecord = false;
    });

    _nextQuestion();
  }

  void _nextQuestion() {
    final quiz = _quiz;
    if (quiz == null) return;

    setState(() {
      _question = quiz.questionAt(_index);
      _selected = null;
    });
  }

  void _answer(String name) {
    final question = _question;
    if (question == null || _selected != null) return;

    final isRight = name == question.correct.name;

    setState(() {
      _selected = name;
      if (isRight) {
        _correctCount++;
        _score += question.level.points;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _streak = 0;
      }
    });

    _nextTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;

      if (_index + 1 >= FlagQuiz.questionCount) {
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

    if (!beatRecord) return;

    setState(() => _best = _score);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, _score);
    } catch (_) {
      // Rekor kaydedilemezse oyun yine de çalışsın.
    }
  }

  // ===============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerStart,
        iconTheme: const IconThemeData(color: AppColors.textAppBar),
        title: const Text(
          "Bayrak Oyunu",
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "$_best",
                    style: const TextStyle(
                      color: AppColors.warning,
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
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) return _buildError();

    if (_finished) {
      return QuizResult(
        score: _score,
        maxScore: FlagQuiz.maxScore,
        correctCount: _correctCount,
        questionCount: FlagQuiz.questionCount,
        bestStreak: _bestStreak,
        best: _best,
        isNewRecord: _isNewRecord,
        onRestart: _startGame,
        onExit: () => Navigator.pop(context),
      );
    }

    if (_question == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return _buildQuestion(_question!);
  }

  // ---------------------------------------------------------------
  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            const Text(
              "Oyun başlatılamadı",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (CountryService.isUsingDemoKey) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning),
                ),
                child: const Text(
                  "Demo API anahtarı yalnızca 1 ülke (Kanada) döndürüyor.\n"
                  "Oyun için en az 4 ülke gerekiyor.\n\n"
                  "restcountries.com/sign-up adresinden ücretsiz anahtar al, "
                  "sonra uygulamayı şöyle başlat:\n\n"
                  "flutter run --dart-define=RC_API_KEY=anahtarin",
                  style: TextStyle(
                    color: AppColors.warning,
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
  Widget _buildQuestion(QuizQuestion question) {
    final levelColor = _levelColor(question.level);

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
                      "Soru ${_index + 1} / ${FlagQuiz.questionCount}",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _levelBadge(question.level, levelColor),
                    const Spacer(),
                    if (_streak >= 2) ...[
                      const Icon(Icons.local_fire_department,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        "$_streak",
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      "$_score puan",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: (_index + 1) / FlagQuiz.questionCount,
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation(levelColor),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          _flagFrame(question.correct.flag),

          const SizedBox(height: 20),

          const Text(
            "Bu bayrak hangi ülkeye ait?",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: question.options
                  .map(
                    (option) => QuizOptionTile(
                      name: option.name,
                      answered: _selected != null,
                      isCorrect: option.name == question.correct.name,
                      isSelected: option.name == _selected,
                      onTap: _selected == null
                          ? () => _answer(option.name)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagFrame(String flag) {
    return AnimatedSwitcher(
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
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
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
            fit: BoxFit.contain,
            // Bilerek alt metin yok: ülke adı cevabın kendisi.
            excludeFromSemantics: true,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 140,
                    width: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 140,
              width: 200,
              child: Icon(Icons.flag, size: 60, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }

  Widget _levelBadge(QuizLevel level, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        "${level.label} · ${level.points}p",
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Color _levelColor(QuizLevel level) => switch (level) {
        QuizLevel.easy => AppColors.success,
        QuizLevel.medium => AppColors.warning,
        QuizLevel.hard => AppColors.danger,
      };
}
