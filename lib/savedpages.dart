import 'package:flutter/material.dart';
import 'package:globeinfo/widgets/saved_data.dart';


class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {

  @override
  Widget build(BuildContext context) {
    final savedCountries = SavedData.savedCountries;

    return Scaffold(
      backgroundColor: const Color(0xFF162440),

      appBar: AppBar(
        backgroundColor: const Color(0xFF162440),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF8FB3DA)),
        title: const Text(
          "Saved Countries",
          style: TextStyle(
            color: Color(0xFF8FB3DA),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: savedCountries.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedCountries.length,
              itemBuilder: (context, index) {
                final country = savedCountries[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1C33),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF223B5E)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag,
                        color: Color(0xFF8FB3DA),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          country,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF8FB3DA),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Color(0xFF8FB3DA),
          ),
          SizedBox(height: 12),
          Text(
            "No Saved Countries",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Tap the star icon to save countries",
            style: TextStyle(
              color: Color(0xFF8FB3DA),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}