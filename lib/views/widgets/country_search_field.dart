import 'package:flutter/material.dart';
import 'package:globeinfo/theme/app_colors.dart';

/// Ana sayfadaki arama kutusu.
class CountrySearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Kutu boşken ve odakta değilken gösterilecek ipucu.
  final String hint;

  final VoidCallback onSubmit;

  const CountrySearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search, color: AppColors.textMuted),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: AppColors.textPrimary),
                onSubmitted: (_) => onSubmit(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close,
                    color: AppColors.textMuted, size: 18),
                tooltip: "Aramayı temizle",
                onPressed: controller.clear,
              ),
            SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onSubmit,
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
