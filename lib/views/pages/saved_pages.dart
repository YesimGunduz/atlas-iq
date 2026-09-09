import 'package:flutter/material.dart';
import 'package:globeinfo/data/saved_data.dart';
import 'package:globeinfo/theme/app_colors.dart';
import 'package:globeinfo/views/pages/details_page.dart';
import 'package:globeinfo/views/widgets/footer.dart';

/// Kaydedilen ülkeler.
///
/// Artık StatefulWidget değil: [SavedData] bir ChangeNotifier olduğu için
/// liste değiştiğinde [ListenableBuilder] kendiliğinden yeniden çiziyor.
/// Önceden her silme işleminden ve detay sayfasından dönüşten sonra elle
/// setState çağırmak gerekiyordu.
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: ListenableBuilder(
        listenable: SavedData.instance,
        builder: (context, _) {
          final saved = SavedData.instance.newestFirst;

          if (saved.isEmpty) return const _EmptyState();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: saved.length,
                    itemBuilder: (context, index) => _SavedTile(
                      country: saved[index],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${saved.length} ülke kayıtlı",
                  style: const TextStyle(
                    color: AppColors.textAppBar,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const HomeFooter(currentIndex: 1),
    );
  }
}

// ---------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
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
                color: AppColors.textPrimary,
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
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.search),
              label: const Text("Ülke ara"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
class _SavedTile extends StatelessWidget {
  final SavedCountry country;

  const _SavedTile({required this.country});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(country.name),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => SavedData.instance.remove(country.name),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CountryDetailPage(query: country.name),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.savedCardStart, AppColors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  country.flag,
                  width: 55,
                  height: 38,
                  fit: BoxFit.cover,
                  semanticLabel: "${country.name} bayrağı",
                  errorBuilder: (_, __, ___) => Container(
                    width: 55,
                    height: 38,
                    color: AppColors.border,
                    child: const Icon(Icons.flag,
                        size: 16, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: "${country.capital}, ",
                        style: const TextStyle(
                          color: AppColors.savedCardText,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: country.continent,
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
  }
}
