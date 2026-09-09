import 'package:flutter/material.dart';
import 'package:globeinfo/theme/app_colors.dart';

/// Bayrak oyununda tek bir şık.
///
/// Cevap verilmeden önce nötr; verildikten sonra doğru şık her hâlükârda
/// yeşil yanar (yanlış bildiysen doğrusunu öğrenesin diye), seçtiğin yanlış
/// şık kırmızı olur.
class QuizOptionTile extends StatelessWidget {
  final String name;

  /// Bu soruya cevap verildi mi?
  final bool answered;

  /// Bu şık doğru cevap mı?
  final bool isCorrect;

  /// Kullanıcının seçtiği şık bu mu?
  final bool isSelected;

  final VoidCallback? onTap;

  const QuizOptionTile({
    super.key,
    required this.name,
    required this.answered,
    required this.isCorrect,
    required this.isSelected,
    this.onTap,
  });

  Color get _background {
    if (!answered) return AppColors.surface;
    if (isCorrect) return AppColors.answerRight;
    if (isSelected) return AppColors.answerWrong;
    return AppColors.surface;
  }

  Color get _border {
    if (!answered) return AppColors.border;
    if (isCorrect) return AppColors.success;
    if (isSelected) return AppColors.danger;
    return AppColors.border;
  }

  IconData? get _icon {
    if (!answered) return null;
    if (isCorrect) return Icons.check_circle;
    if (isSelected) return Icons.cancel;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: isCorrect ? AppColors.success : AppColors.danger,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
