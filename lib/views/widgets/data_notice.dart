import 'package:flutter/material.dart';
import 'package:globeinfo/services/country_services.dart';
import 'package:globeinfo/theme/app_colors.dart';

/// Verinin nereden geldiğini ve eksik olup olmadığını anlatan bilgi şeridi.
///
/// Üç durum var:
/// - her şey yolunda   -> hiçbir şey göstermez
/// - önbellekten açıldı -> sakin bir bilgi satırı
/// - demo anahtarı ya da eksik liste -> turuncu uyarı
class DataNotice extends StatelessWidget {
  /// Ekranda kaç ülke var.
  final int loadedCount;

  const DataNotice({super.key, required this.loadedCount});

  @override
  Widget build(BuildContext context) {
    if (loadedCount == 0) return const SizedBox.shrink();

    final total = CountryService.reportedTotal;
    final incomplete = total != null && loadedCount < total;
    final fromCache = CountryService.loadedFromCache;
    final demo = CountryService.demoResponseDetected;

    if (!demo && !incomplete && !fromCache) return const SizedBox.shrink();

    // Önbellekten açıldıysa uyarı değil, bilgi.
    if (fromCache && !demo && !incomplete) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            const Icon(Icons.offline_bolt_outlined,
                color: AppColors.textMuted, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Kayıtlı veriden açıldı${_ageText()} · arka planda güncelleniyor",
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final countText = total != null
        ? "$loadedCount / $total ülke yüklendi"
        : "$loadedCount ülke yüklendi";

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warningBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                color: AppColors.warning, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    countText,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CountryService.isUsingDemoKey
                        ? "Demo anahtarı sadece örnek veri döndürüyor. "
                            "Tam liste için restcountries.com'dan ücretsiz "
                            "anahtar al ve uygulamayı şöyle başlat:\n"
                            "flutter run --dart-define=RC_API_KEY=anahtarin"
                        : "API tam listeyi döndürmedi. Yenilemek için "
                            "uygulamayı yeniden başlatabilirsin.",
                    style: const TextStyle(
                      color: AppColors.warningText,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "· 3 saat önce" gibi bir ek. Tarih bilinmiyorsa boş.
  String _ageText() {
    final date = CountryService.dataDate;
    if (date == null) return "";

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return " · ${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return " · ${diff.inHours} saat önce";
    return " · ${diff.inDays} gün önce";
  }
}
