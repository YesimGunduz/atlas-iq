import 'package:flutter/material.dart';
import 'package:globeinfo/i18n/locale_controller.dart';
import 'package:globeinfo/theme/app_colors.dart';

/// Oyun bitince gösterilen sonuç ekranı.
class QuizResult extends StatelessWidget {
  final int score;
  final int maxScore;
  final int correctCount;
  final int questionCount;
  final int bestStreak;
  final int best;
  final bool isNewRecord;

  final VoidCallback onRestart;
  final VoidCallback onExit;

  const QuizResult({
    super.key,
    required this.score,
    required this.maxScore,
    required this.correctCount,
    required this.questionCount,
    required this.bestStreak,
    required this.best,
    required this.isNewRecord,
    required this.onRestart,
    required this.onExit,
  });

  String get _message {
    if (correctCount == questionCount) return S.resultPerfect;
    if (score >= maxScore * 0.7) return S.resultGood;
    if (score >= maxScore * 0.4) return S.resultOk;
    return S.resultPoor;
  }

  @override
  Widget build(BuildContext context) {
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
                isNewRecord ? Icons.emoji_events : Icons.flag_circle,
                size: 80,
                color: isNewRecord ? AppColors.warning : AppColors.accent,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              S.scoreOf(score, maxScore),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              S.correctOf(correctCount, questionCount),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            if (isNewRecord) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Text(
                  S.newRecord,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stat(S.longestStreak, "$bestStreak"),
                const SizedBox(width: 32),
                _stat(S.record, "$best"),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onRestart,
                icon: const Icon(Icons.refresh),
                label: Text(S.playAgain),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onExit,
                child: Text(
                  S.backHome,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
