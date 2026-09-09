import 'package:flutter/material.dart';
import 'package:globeinfo/data/saved_data.dart';
import 'package:globeinfo/services/country_services.dart';
import 'package:globeinfo/services/visa_dataservice.dart';
import 'package:globeinfo/theme/app_colors.dart';
import 'package:globeinfo/views/pages/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// En az bu kadar süre logo ekranda kalsın.
  static const Duration _minDuration = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// Splash ekranı beklerken veriyi gerçekten indiriyoruz.
  /// Böylece "Dünya verileri yükleniyor" yazısı doğru oluyor ve ana sayfa
  /// açıldığında liste hazır geliyor.
  Future<void> _boot() async {
    final started = DateTime.now();

    // Veri yüklemesi bu süreyi aşarsa splash'te bekletmiyoruz; ana sayfaya
    // geçiyoruz, yükleme orada göstergesiyle birlikte devam ediyor.
    // (Aksi hâlde yavaş ağda kullanıcı dakikalarca splash'te kalabiliyordu.)
    await Future.any([
      _loadEverything(),
      Future.delayed(const Duration(seconds: 5)),
    ]);

    final elapsed = DateTime.now().difference(started);
    final remaining = _minDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _loadEverything() async {
    try {
      await SavedData.instance.load();
      await VisaDatabase.load();
      await CountryService.getAllCountries();
    } catch (_) {
      // Hata olursa ana sayfa "Tekrar dene" ekranını gösterecek.
    }
  }

  @override
  Widget build(BuildContext context) {
    const shadows = [
      Shadow(blurRadius: 20, color: AppColors.shadowGlow),
      Shadow(blurRadius: 40, color: AppColors.shadowSoft),
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND
          Image.asset(
            "assets/images/splashatlas.webp",
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: AppColors.background),
          ),

          // OVERLAY
          Container(color: Colors.black.withValues(alpha: 0.35)),

          // CONTENT
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),

                const Text(
                  "AtlasIQ",
                  style: TextStyle(
                    fontSize: 34,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: shadows,
                  ),
                ),

                const Spacer(flex: 3),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Ülkeleri, bayrakları ve güncel bilgileri tek yerde keşfet",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.splashText,
                      fontSize: 16,
                      shadows: shadows,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),

                const SizedBox(height: 10),

                const Text(
                  "Dünya verileri yükleniyor...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: shadows,
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
