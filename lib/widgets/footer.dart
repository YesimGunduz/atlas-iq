import 'package:flutter/material.dart';
import 'package:globeinfo/savedpages.dart';
import 'package:globeinfo/homepage.dart';

class HomeFooter extends StatefulWidget {
  const HomeFooter({super.key});

  @override
  State createState() => _HomeFooterState();
}

class _HomeFooterState extends State<HomeFooter> {
  int _selectedIndex = 0;

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _item(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        _onTap(index);

        // ⭐ SAVED PAGE NAVIGATION
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SavedPage()),
          );
        } else if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HomePage()),
          );
        }
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1424),
        border: Border(top: BorderSide(color: Color(0x1A609FFA))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [_item(Icons.home, "Home", 0), _item(Icons.star, "Saved", 1)],
      ),
    );
  }
}
