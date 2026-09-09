import 'package:flutter/material.dart';

/// Uygulamanın renk paleti.
///
/// Daha önce bu değerler 151 ayrı yerde tek tek yazılıydı; vurgu rengini
/// değiştirmek dosya dosya dolaşmak demekti. Artık tek kaynak burası.
///
/// Not: aşağıda birbirine çok yakın birkaç mavi-gri var (textLabel,
/// textAppBar, textBody). Görünümü bozmamak için hepsi olduğu gibi taşındı;
/// istersen ikisini üçünü birleştirip paleti daha da sadeleştirebiliriz.
class AppColors {
  AppColors._();

  // ===============================================================
  // ZEMİNLER
  // ===============================================================
  /// Ana sayfa zemini
  static const Color background = Color(0xFF0A1628);

  /// Detay sayfası zemini, arama kutusu, oyun şıkları
  static const Color surface = Color(0xFF162440);

  /// Ülke kartı, oyunda bayrak çerçevesi
  static const Color surfaceRaised = Color(0xFF122038);

  /// Detay sayfasındaki bilgi kartları
  static const Color surfaceCard = Color(0xFF162A45);

  /// Canlı saat kutusu, not kutusu
  static const Color surfaceSunken = Color(0xFF0F1C33);

  /// Üst bar gradyanı ve oyun app bar'ı
  static const Color headerStart = Color(0xFF0B1220);
  static const Color headerEnd = Color(0xFF172238);

  /// Hero kartı gradyanı
  static const Color heroStart = Color(0xFF121B2E);
  static const Color heroEnd = Color(0xFF172238);

  /// Alt menü
  static const Color footer = Color(0xFF0B1424);

  /// Filtre paneli
  static const Color sheet = Color(0xFF0B0B0B);

  // ===============================================================
  // KENARLIKLAR
  // ===============================================================
  static const Color border = Color(0xFF223B5E);

  /// Alt menünün üst çizgisi
  static const Color borderSoft = Color(0x1A609FFA);

  /// Hero kartının mavimsi kenarlığı
  static const Color borderAccent = Color(0x334F8CFF);

  // ===============================================================
  // METİN
  // ===============================================================
  static const Color textPrimary = Colors.white;

  /// İkincil metin: etiketler, açıklamalar
  static const Color textSecondary = Color(0xFF8AA4C2);

  /// Soluk metin ve pasif ikonlar
  static const Color textMuted = Color(0xFF7A9CC4);

  /// Detay sayfasındaki satır başlıkları
  static const Color textLabel = Color(0xFF7FA6D6);

  /// App bar ikon ve başlıkları
  static const Color textAppBar = Color(0xFF8FB3DA);

  /// Kart içi açıklama metni
  static const Color textBody = Color(0xFF9DB2CE);

  /// En soluk metin: sorumluluk reddi
  static const Color textDim = Color(0xFF5F7DA3);

  // ===============================================================
  // VURGU
  // ===============================================================
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentDark = Color(0xFF2563EB);
  static const Color accentLight = Color(0xFF4DA3FF);

  /// Aktif sekme zemini (vurgunun %10'u)
  static const Color accentSoft = Color(0x1A3B82F6);

  /// "Kuralları gör" düğmesi
  static const Color accentDeep = Color(0xFF073559);

  // ===============================================================
  // DURUM RENKLERİ
  // ===============================================================
  /// Vizesiz / doğru cevap
  static const Color success = Color(0xFF2ED573);

  /// Kapıda vize / uyarı / rekor
  static const Color warning = Color(0xFFFFA502);
  static const Color warningSoft = Color(0x1AFFA502);
  static const Color warningBorder = Color(0x66FFA502);
  static const Color warningText = Color(0xFFD6A45A);

  /// Vize gerekli / yanlış cevap
  static const Color danger = Color(0xFFFF4757);

  /// Oyunda doğru ve yanlış şıkkın zemini
  static const Color answerRight = Color(0xFF1B5E3F);
  static const Color answerWrong = Color(0xFF6B2130);

  /// Seyahat Modu kartının gradyanı
  static const Color travelCardStart = Color.fromARGB(255, 75, 131, 168);
  static const Color travelCardEnd = Color.fromARGB(255, 175, 184, 190);

  /// Kaydedilen ülke kartının gradyanı
  static const Color savedCardStart = Color.fromARGB(255, 168, 194, 213);

  /// Kaydedilen kartta başkent metni
  static const Color savedCardText = Color.fromARGB(255, 41, 54, 68);

  /// Splash açıklama metni
  static const Color splashText = Color.fromARGB(255, 249, 249, 249);

  // ===============================================================
  // GÖLGELER
  // ===============================================================
  static const Color shadow = Color(0x66000000);

  /// Splash yazılarının gölgeleri
  static const Color shadowGlow = Color.fromARGB(255, 7, 33, 79);
  static const Color shadowSoft = Color.fromARGB(110, 0, 0, 0);

  // ===============================================================
  // VİZE DURUMU
  // ===============================================================
  /// Vize türüne karşılık gelen renk. Hem liste rozetinde, hem filtre
  /// panelinde, hem detay sayfasında aynı renk kullanılsın diye tek yerde.
  static Color visa(String? type) {
    switch (type) {
      case "Visa Free":
        return success;
      case "E-Visa":
        return accentLight;
      case "Visa On Arrival":
        return warning;
      case "Visa Required":
        return danger;
      default:
        return textMuted;
    }
  }
}
