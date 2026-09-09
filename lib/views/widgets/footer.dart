import 'package:flutter/material.dart';
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
          color: isActive ? const Color(0x1A3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF7A9CC4),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF7A9CC4),
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
        color: Color(0xFF0B1424),
        border: Border(top: BorderSide(color: Color(0x1A609FFA))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _item(context, Icons.home, "Home", 0, () => _goHome(context)),
              _item(context, Icons.star, "Saved", 1, () => _goSaved(context)),
            ],
          ),
        ),
      ),
    );
  }
}
