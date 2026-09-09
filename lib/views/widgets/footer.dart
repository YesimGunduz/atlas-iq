import 'package:flutter/material.dart';
import 'package:globeinfo/theme/app_colors.dart';
import 'package:globeinfo/views/pages/saved_pages.dart';

/// Alt menü.
///
/// [currentIndex]: 0 = Home, 1 = Saved, -1 = ikisi de değil (detay sayfası).
/// Aynı sekmeye tekrar basınca hiçbir şey yapmaz; böylece sayfa yığını
/// sonsuza kadar büyümez.
class HomeFooter extends StatelessWidget {
  final int currentIndex;

  const HomeFooter({super.key, this.currentIndex = 0});

  void _goHome(BuildContext context) {
    if (currentIndex == 0) return;
    // Splash pushReplacement kullandığı için HomePage yığının en altında.
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _goSaved(BuildContext context) {
    if (currentIndex == 1) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedPage()),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    VoidCallback onTap,
  ) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.accent
                  : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? AppColors.accent
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.footer,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _item(context, Icons.home, "Ana sayfa", 0, () => _goHome(context)),
              _item(context, Icons.star, "Kaydedilenler", 1, () => _goSaved(context)),
            ],
          ),
        ),
      ),
    );
  }
}
