import 'package:flutter/material.dart';
import 'package:globeinfo/i18n/locale_controller.dart';
import 'package:globeinfo/theme/app_colors.dart';

/// TR / EN geçişi. Seçim diske kaydediliyor.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final current = LocaleController.instance.locale;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppLocale.values
            .map((locale) => _segment(locale, locale == current))
            .toList(),
      ),
    );
  }

  Widget _segment(AppLocale locale, bool selected) {
    return Semantics(
      selected: selected,
      button: true,
      label: locale.nativeName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => LocaleController.instance.setLocale(locale),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              locale.short,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
