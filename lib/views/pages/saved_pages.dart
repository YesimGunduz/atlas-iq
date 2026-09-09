import 'package:flutter/material.dart';
import 'package:globeinfo/theme/app_colors.dart';
import 'package:globeinfo/data/saved_data.dart';

import 'package:globeinfo/views/widgets/footer.dart';
import 'details_page.dart';
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
      backgroundColor: AppColors.surface,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textAppBar),
        title: const Text(
          "Kaydedilenler",
          style: TextStyle(
            color: AppColors.textAppBar,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: savedCountries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_border,
                        color: AppColors.textLabel, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      "Henüz kayıtlı ülke yok",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Bir ülkenin sayfasını açıp sağ üstteki yıldıza "
                      "dokunarak buraya ekleyebilirsin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () => Navigator.popUntil(
                          context, (route) => route.isFirst),
                      icon: const Icon(Icons.search),
                      label: const Text("Ülke ara"),
                    ),
                  ],
                ),
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

                          onDismissed: (_) async {
                            await SavedData.remove(item.name);
                            if (mounted) setState(() {});
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
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CountryDetailPage(query: item.name),
                                ),
                              );
                              if (mounted) setState(() {});
                            },

                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.savedCardStart,
                                    AppColors.surface,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border,
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
                                      semanticLabel: "${item.name} bayrağı",
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 55,
                                        height: 38,
                                        color: AppColors.border,
                                        child: const Icon(
                                          Icons.flag,
                                          size: 16,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
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
                                              color: AppColors.savedCardText,
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
                    "${savedCountries.length} ülke kayıtlı",
                    style: const TextStyle(
                      color: AppColors.textAppBar,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: const HomeFooter(currentIndex: 1),
    );
  }
}
