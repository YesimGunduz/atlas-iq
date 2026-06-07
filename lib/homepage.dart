import 'dart:async';
import 'package:flutter/material.dart';
import 'package:globeinfo/widgets/footer.dart';
import 'widgets/header.dart';
import 'widgets/filtersheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 🔥 HINTS
  final List<String> _hints = [
    "Search country or flag...",
    "Discover countries in real time",
    "Search any country instantly",
    "Get live country data",
  ];

  int _hintIndex = 0;
  String _currentHint = "";
  Timer? _hintTimer;

  bool _isActive = false;

  @override
  void initState() {
    super.initState();

    _currentHint = _hints[_hintIndex];

    // 🔥 rotate hints
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _hintIndex = (_hintIndex + 1) % _hints.length;
        _currentHint = _hints[_hintIndex];
      });
    });

    // 🔥 input + focus control
    _searchCtrl.addListener(_updateState);
    _focusNode.addListener(_updateState);
  }

  void _updateState() {
    setState(() {
      _isActive = _searchCtrl.text.isNotEmpty || _focusNode.hasFocus;
    });
  }

  void _onSearch() {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    Navigator.pushNamed(context, '/detail', arguments: query);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------- HERO ----------------
  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.maxFinite,
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF121B2E), Color(0xFF172238)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x334F8CFF)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore, color: Color(0xFF3B82F6), size: 20),
                SizedBox(width: 10),
                Text(
                  "Explore The World",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "Discover countries, flags, languages with live data",
              style: TextStyle(color: Color(0xFF9DB2CE), fontSize: 13),
            ),
            SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatBox(icon: Icons.public, value: "195", label: "Countries"),
                _StatBox(icon: Icons.flag, value: "250+", label: "Flags"),
                _StatBox(
                  icon: Icons.language,
                  value: "7000+",
                  label: "Languages",
                ),
                _StatBox(icon: Icons.flash_on, value: "LIVE", label: "Data"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartTravelCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 75, 131, 168),
              Color.fromARGB(255, 175, 184, 190),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x334F8CFF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.public, color: Color.fromARGB(255, 7, 53, 89)),
            const SizedBox(width: 14),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Smart Travel Mode",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Discover visa, passport & ID options",
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
  onTap: () async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FilterSheet(),
    );

    if (result != null) {
      print("Selected Filters: $result");

      // 🔥 İLERİDE BURADA SONUÇ SAYFASINA GİDECEKSİN
      // Navigator.pushNamed(context, '/results', arguments: result);
    }
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 7, 53, 89),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      "Explore Rules",
      style: TextStyle(color: Colors.white),
    ),
  ),
),
          ],
        ),
      ),
    );
  }

  // ---------------- SEARCH BAR ----------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF162440),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x26609FFA)),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search, color: Color(0xFF7A9CC4)),
            ),

            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _onSearch(),

                decoration: InputDecoration(
                  hintText: _isActive ? "" : _currentHint,
                  hintStyle: const TextStyle(color: Color(0xFF7A9CC4)),
                  border: InputBorder.none,
                ),
              ),
            ),

            GestureDetector(
              onTap: _onSearch,
              child: Container(
                margin: const EdgeInsets.all(8),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeader(),
            const SizedBox(height: 16),
            _buildHeroCard(),
            const SizedBox(height: 22),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildSmartTravelCard(),
            const Spacer(),
            const HomeFooter(),
          ],
        ),
      ),
    );
  }
}

// ---------------- STAT BOX ----------------
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
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8AA4C2), fontSize: 11),
        ),
      ],
    );
  }
}
