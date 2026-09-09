import 'package:flutter/material.dart';
import 'package:globeinfo/data/saved_data.dart';
import 'package:globeinfo/services/country_services.dart';
import 'package:globeinfo/services/visa_dataservice.dart';
import 'package:globeinfo/views/widgets/footer.dart';

class CountryDetailPage extends StatefulWidget {
  final String query;

  const CountryDetailPage({super.key, required this.query});

  @override
  State<CountryDetailPage> createState() => _CountryDetailPageState();
}

class _CountryDetailPageState extends State<CountryDetailPage> {
  Map<String, dynamic>? country;

  bool isLoading = true;
  bool isSaved = false;
  String? errorMessage;

  String currencyCode = "";
  String tryRate = "-";
  String timeDifference = "-";

  @override
  void initState() {
    super.initState();
    fetchCountry();
  }

  @override
  void didUpdateWidget(covariant CountryDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) fetchCountry();
  }

  // ---------------------------------------------------------------
  Future<void> fetchCountry() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      tryRate = "";
      currencyCode = "";
    });

    try {
      await VisaDatabase.load();

      final data = await CountryService.getCountry(widget.query);

      if (!mounted) return;

      if (data == null) {
        setState(() {
          country = null;
          isLoading = false;
        });
        return;
      }

      // --- Ekranı HEMEN çiz. Kur gibi yavaş olabilecek şeyleri bekletme. ---
      final name = CountryService.countryName(data);

      // Saat farkı (yerel hesap, anında)
      String diffText = "-";
      final zones = data["timezones"];
      if (zones is List && zones.isNotEmpty) {
        final countryMinutes = _offsetMinutes(zones.first.toString());
        const turkeyMinutes = 3 * 60;
        final diff = countryMinutes - turkeyMinutes;

        if (diff > 0) {
          diffText = "${_durationText(diff)} ileri";
        } else if (diff < 0) {
          diffText = "${_durationText(diff.abs())} geri";
        } else {
          diffText = "Türkiye ile aynı saat";
        }
      }

      // Para birimi kodu
      final code = (data["currencyCode"] ?? "").toString();

      setState(() {
        country = data;
        isSaved = SavedData.contains(name);
        timeDifference = diffText;
        currencyCode = code;
        isLoading = false;
      });

      // --- Kur arka planda gelsin, sayfa çoktan açıldı. ---
      if (code.isEmpty) {
        if (mounted) setState(() => tryRate = "-");
        return;
      }

      final rate = await CountryService.getTryRate(code);
      if (!mounted) return;
      setState(() => tryRate = rate);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        country = null;
        isLoading = false;
        errorMessage = "Bilgiler alınamadı. Bağlantını kontrol et.\n($e)";
      });
    }
  }

  // ---------------------------------------------------------------
  // SAAT DİLİMİ
  // ---------------------------------------------------------------
  /// "UTC+05:30" / "UTC-03:00" / "UTC" -> dakika cinsinden fark
  static int _offsetMinutes(String timezone) {
    final match =
        RegExp(r'UTC([+-])(\d{1,2})(?::(\d{2}))?').firstMatch(timezone);
    if (match == null) return 0;

    final sign = match.group(1) == "-" ? -1 : 1;
    final hours = int.tryParse(match.group(2) ?? "0") ?? 0;
    final minutes = int.tryParse(match.group(3) ?? "0") ?? 0;

    return sign * (hours * 60 + minutes);
  }

  static String _durationText(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return "$h saat";
    return "$h saat $m dakika";
  }

  // ---------------------------------------------------------------
  // GÖSTERİM YARDIMCILARI
  // ---------------------------------------------------------------
  String get _name =>
      country == null ? widget.query : CountryService.countryName(country!);

  String getCurrency() {
    final code = (country?['currencyCode'] ?? "").toString();
    if (code.isEmpty) return "-";

    final name = (country?['currencyName'] ?? "").toString();
    return name.isEmpty ? code : "$code ($name)";
  }

  String getTimezone() {
    final zones = country?['timezones'];
    if (zones is! List || zones.isEmpty) return "-";
    return zones.join(", ");
  }

  List<String> get _zones {
    final zones = country?['timezones'];
    return zones is List ? zones.map((e) => e.toString()).toList() : const [];
  }

  String getPopulation() {
    final pop = country?['population'];
    if (pop is! num) return "-";

    // 84000000 -> 84.000.000
    final digits = pop.toInt().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String getLanguages() {
    final langs = country?['languages'];
    if (langs is! List || langs.isEmpty) return "-";
    return langs.join(", ");
  }

  String get _tryRateText {
    if (currencyCode.isEmpty) return "-";
    if (tryRate.isEmpty) return "hesaplanıyor...";
    if (tryRate == "-") return "kur alınamadı";
    return "1 $currencyCode = $tryRate TL";
  }

  // ---------------------------------------------------------------
  Future<void> _toggleSaved() async {
    final data = country;
    if (data == null) return;

    final name = CountryService.countryName(data);
    final messenger = ScaffoldMessenger.of(context);
    final willSave = !isSaved;

    setState(() => isSaved = willSave);

    if (willSave) {
      await SavedData.add(
        SavedCountry(
          name: name,
          capital: CountryService.capitalOf(data),
          flag: CountryService.flagUrl(data),
          continent: (data['region'] ?? "-").toString(),
        ),
      );
    } else {
      await SavedData.remove(name);
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF162A45),
          content: Text(
            willSave
                ? "$name kaydedildi"
                : "$name kaydedilenlerden çıkarıldı",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------
  Widget infoCard(String title, String value, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162A45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF223B5E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF7FA6D6), fontSize: 13),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dualLiveClock() {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final nowUtc = DateTime.now().toUtc();

        final turkey = nowUtc.add(const Duration(hours: 3));

        final zones = _zones;
        final offset =
            zones.isNotEmpty ? _offsetMinutes(zones.first) : 0;
        final countryTime = nowUtc.add(Duration(minutes: offset));

        String format(DateTime t) =>
            "${t.hour.toString().padLeft(2, '0')}:"
            "${t.minute.toString().padLeft(2, '0')}:"
            "${t.second.toString().padLeft(2, '0')}";

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1C33),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF223B5E)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _clockColumn("TÜRKİYE", format(turkey), Colors.greenAccent),
              _clockColumn(
                _name.toUpperCase(),
                format(countryTime),
                Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _clockColumn(String label, String time, Color color) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF7FA6D6), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Color _visaColor(String? v) {
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

  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162440),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162440),
        iconTheme: const IconThemeData(color: Color(0xFF8FB3DA)),
        title: Text(_name, style: const TextStyle(color: Colors.white)),
        actions: [
          if (country != null)
            IconButton(
              onPressed: _toggleSaved,
              icon: Icon(
                isSaved ? Icons.star : Icons.star_border,
                color: Colors.yellow,
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: const HomeFooter(currentIndex: -1),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    if (country == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, color: Color(0xFF7FA6D6), size: 40),
              const SizedBox(height: 12),
              Text(
                errorMessage ??
                    "\"${widget.query}\" bulunamadı.\n"
                        "Ülke adını İngilizce yazmayı dene (ör. Germany).",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: fetchCountry,
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrar dene"),
              ),
            ],
          ),
        ),
      );
    }

    final visa = VisaDatabase.visaOf(_name);
    final entry = VisaDatabase.entryOf(_name);
    final note = VisaDatabase.noteOf(_name);
    final flag = CountryService.flagUrl(country!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              flag,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.flag,
                size: 60,
                color: Color(0xFF7FA6D6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          dualLiveClock(),

          infoCard("Saat farkı", timeDifference),
          infoCard("Başkent", CountryService.capitalOf(country!)),
          infoCard("Bölge", (country!['region'] ?? "-").toString()),
          infoCard("Nüfus", getPopulation()),
          infoCard("Diller", getLanguages()),
          infoCard("Para birimi", getCurrency()),
          infoCard("TL karşılığı", _tryRateText,
              valueColor: Colors.greenAccent),
          infoCard("Saat dilimi", getTimezone()),

          if (visa != null)
            infoCard("Vize", visa, valueColor: _visaColor(visa)),
          if (entry != null) infoCard("Giriş", entry),

          if (note != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1C33),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF223B5E)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      color: Color(0xFF7FA6D6), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: Color(0xFF9DB2CE),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (visa == null)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                "Bu ülke için henüz vize kaydı yok",
                style: TextStyle(color: Color(0xFF7FA6D6), fontSize: 12),
              ),
            ),

          if (visa != null && VisaDatabase.disclaimer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                "${VisaDatabase.passport} için. ${VisaDatabase.disclaimer}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5F7DA3),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
