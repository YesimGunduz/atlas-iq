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

  Color visaColor(String v) {
    switch (v) {
      case "Visa Free":
        return const Color(0xFF2ED573);
      case "E-Visa":
        return const Color(0xFF4DA3FF);
      case "Visa On Arrival":
        return const Color(0xFFFFA502);
      case "Visa Required":
        return const Color(0xFFFF4757);
      default:
        return Colors.white;
    }
  }

  Widget chip(String text, bool selected, VoidCallback onTap, {Color? color}) {
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
          border: Border.all(color: selected ? c : Colors.white24),
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

  void applyFilters() {
    Navigator.pop(context, {
      "visa": visaType,
      "entry": entryType,
    });
  }

  void clear() {
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

          const Text(
            "Filter Countries",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // ENTRY
          const Text("Entry Type", style: TextStyle(color: Colors.white)),
          Wrap(
            children: entryOptions.map((e) {
              return chip(
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

          const SizedBox(height: 12),

          // VISA
          const Text("Visa Type", style: TextStyle(color: Colors.white)),
          Wrap(
            children: visaOptions.map((v) {
              return chip(
                v,
                visaType == v,
                () {
                  setState(() {
                    visaType = visaType == v ? null : v;
                  });
                },
                color: visaColor(v),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: clear,
                  child: const Text("Clear"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: applyFilters,
                  child: const Text("Apply"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}