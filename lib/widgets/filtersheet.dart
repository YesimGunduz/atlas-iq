import 'package:flutter/material.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? visaType;
  String? entryType;

  final Color accent = const Color(0xFF4DA3FF);

  final List<String> visaOptions = [
    "Visa Free",
    "E-Visa",
    "Visa On Arrival",
    "Visa Required",
  ];

  final List<String> entryOptions = [
    "ID Only",
    "Passport Required",
  ];

  Color _visaColor(String v) {
    switch (v) {
      case "Visa Free":
        return const Color(0xFF2ED573); // green
      case "E-Visa":
        return const Color(0xFF4DA3FF); // blue
      case "Visa On Arrival":
        return const Color(0xFFFFA502); // orange
      case "Visa Required":
        return const Color(0xFFFF4757); // red
      default:
        return Colors.white;
    }
  }

  Widget _chip(String text, bool selected, VoidCallback onTap, {Color? color}) {
    final c = color ?? Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c : Colors.white24,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? c : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _applyFilters() {
    Navigator.pop(context, {
      "visa": visaType,
      "entry": entryType,
    });
  }

  void _clear() {
    setState(() {
      visaType = null;
      entryType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B0B0B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "Filter Countries",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // 🪪 ENTRY
          _sectionTitle(
            "Entry Type",
            "Choose how you can enter the country",
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Wrap(
              children: entryOptions.map((e) {
                return _chip(
                  e,
                  entryType == e,
                  () {
                    setState(() {
                      entryType = entryType == e ? null : e;
                    });
                  },
                  color: accent,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // 🌍 VISA
          _sectionTitle(
            "Visa Type",
            "Select visa requirement level",
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Wrap(
              children: visaOptions.map((v) {
                final color = _visaColor(v);

                return _chip(
                  v,
                  visaType == v,
                  () {
                    setState(() {
                      visaType = visaType == v ? null : v;
                    });
                  },
                  color: color,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 22),

          // ACTIONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Clear"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Apply Filters",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}