import 'package:flutter/material.dart';
import 'package:globeinfo/theme/app_colors.dart';

/// Ana sayfanın üstündeki tanıtım kartı.
/// Sayılar gerçek veriden geliyor; hiçbiri sabit yazılı değil.
class HeroCard extends StatelessWidget {
  final int countryCount;
  final int visaRuleCount;
  final int languageCount;
  final bool isLoading;

  const HeroCard({
    super.key,
    required this.countryCount,
    required this.visaRuleCount,
    required this.languageCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.heroStart, AppColors.heroEnd],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderAccent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.explore, color: AppColors.accent, size: 20),
                SizedBox(width: 10),
                Text(
                  "Dünyayı Keşfet",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Ülkeler, bayraklar ve diller — güncel verilerle",
              style: TextStyle(color: AppColors.textBody, fontSize: 13),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatBox(
                  icon: Icons.public,
                  value: countryCount == 0 ? "—" : "$countryCount",
                  label: "Ülke",
                ),
                _StatBox(
                  icon: Icons.card_travel,
                  value: "$visaRuleCount",
                  label: "Vize kaydı",
                ),
                _StatBox(
                  icon: Icons.language,
                  value: languageCount == 0 ? "—" : "$languageCount",
                  label: "Dil",
                ),
                _StatBox(
                  icon: Icons.flash_on,
                  value: isLoading ? "..." : "GÜNCEL",
                  label: "Veri",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
