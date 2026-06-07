import 'package:flutter/material.dart';
import 'widgets/saved_data.dart';
import 'widgets/footer.dart';
import 'countryservices.dart';
import 'detailspage.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  @override
  Widget build(BuildContext context) {
    final savedCountries = SavedData.savedCountries.reversed.toList();

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
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: savedCountries.isEmpty
          ? const Center(
              child: Text(
                "No Saved Countries",
                style: TextStyle(color: Colors.white),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: savedCountries.length,
                      itemBuilder: (context, index) {
                        final item = savedCountries[index];

                        return Dismissible(
                          key: Key(item.name),
                          direction: DismissDirection.endToStart,

                          onDismissed: (_) {
                            setState(() {
                              SavedData.savedCountries.removeWhere(
                                (e) => e.name == item.name,
                              );
                            });
                          },

                          background: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),

                          // ⭐ TIKLANABİLİR KART BURASI
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CountryDetailPage(query: item.name),
                                ),
                              );
                            },

                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 168, 194, 213),
                                    Color(0xFF162440),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF223B5E),
                                ),
                              ),

                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      item.flag,
                                      width: 55,
                                      height: 38,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text.rich(
                                          TextSpan(
                                            text: "${item.capital}, ",
                                            style: const TextStyle(
                                              color: Color.fromARGB(
                                                255,
                                                41,
                                                54,
                                                68,
                                              ),
                                              fontSize: 13,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: item.continent,
                                                style: const TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "${savedCountries.length} Countries Saved",
                    style: const TextStyle(
                      color: Color(0xFF8FB3DA),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: const SizedBox(height: 80, child: HomeFooter()),
    );
  }
}
