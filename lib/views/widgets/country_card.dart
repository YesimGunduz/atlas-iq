import 'package:flutter/material.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/data/labels.dart';
import 'package:globeinfo/theme/app_colors.dart';

/// Ana sayfadaki liste satırı: bayrak, ülke adı, başkent ve vize rozeti.
class CountryCard extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;

  const CountryCard({
    super.key,
    required this.country,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visa = country.visa;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                country.flag,
                width: 48,
                height: 34,
                fit: BoxFit.cover,
                semanticLabel: "${country.name} bayrağı",
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 34,
                  color: AppColors.border,
                  child: const Icon(Icons.flag,
                      size: 16, color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    country.capital,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (visa != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.visa(visa).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.visa(visa)),
                ),
                child: Text(
                  Labels.visa(visa),
                  style: TextStyle(color: AppColors.visa(visa), fontSize: 10),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
