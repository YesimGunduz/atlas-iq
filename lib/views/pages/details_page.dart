import 'package:flutter/material.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/data/labels.dart';
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
  Country? country;

  bool isLoading = true;
  bool isSaved = false;
  String? errorMessage;

  /// Boş: kur henüz yükleniyor. "-": kur alınamadı.
  String tryRate = "";
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

      // Ekranı HEMEN çiz; kur gibi yavaş olabilecek şeyleri bekletme.
      setState(() {
        country = data;
        isSaved = SavedData.contains(data.name);
        timeDifference = _timeDifferenceText(data);
        isLoading = false;
      });

      // Kur arka planda gelsin, sayfa çoktan açıldı.
      if (data.currencyCode.isEmpty) {
        if (mounted) setState(() => tryRate = "-");
        return;
      }

      final rate = await CountryService.getTryRate(data.currencyCode);
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
  // SAAT
  // ---------------------------------------------------------------
  /// Türkiye kalıcı olarak UTC+3.
  static const int _turkeyOffsetMinutes = 3 * 60;

  static String _timeDifferenceText(Country c) {
    if (c.timezones.isEmpty) return "-";

    final diff = c.utcOffsetMinutes - _turkeyOffsetMinutes;

    if (diff > 0) return "${_durationText(diff)} ileri";
    if (diff < 0) return "${_durationText(diff.abs())} geri";
    return "Türkiye ile aynı saat";
  }

  static String _durationText(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return "$h saat";
    return "$h saat $m dakika";
  }

  // ---------------------------------------------------------------
  String get _name => country?.name ?? widget.query;

  String get _tryRateText {
    final c = country;
    if (c == null || c.currencyCode.isEmpty) return "-";
    if (tryRate.isEmpty) return "hesaplanıyor...";
    if (tryRate == "-") return "kur alınamadı";
    return "1 ${c.currencyCode} = $tryRate TL";
  }

  // ---------------------------------------------------------------
  Future<void> _toggleSaved() async {
    final data = country;
    if (data == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final willSave = !isSaved;

    setState(() => isSaved = willSave);

    if (willSave) {
      await SavedData.add(
        SavedCountry(
          name: data.name,
          capital: data.capital,
          flag: data.flag,
          continent: data.region,
        ),
      );
    } else {
      await SavedData.remove(data.name);
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF162A45),
          content: Text(
            willSave
                ? "${data.name} kaydedildi"
                : "${data.name} kaydedilenlerden çıkarıldı",
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

        final turkey = nowUtc.add(const Duration(minutes: _turkeyOffsetMinutes));
        final countryTime =
            nowUtc.add(Duration(minutes: country?.utcOffsetMinutes ?? 0));

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
              tooltip: isSaved ? "Kaydedilenlerden çıkar" : "Kaydet",
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

    final c = country;

    if (c == null) {
      return Center(
        child: SingleChildScrollView(
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

    // Vize bilgisi listeden iliştirilmiş olabilir; olmadıysa dosyadan oku.
    final visa = c.visa ?? VisaDatabase.visaOf(c.name);
    final entry = c.entry ?? VisaDatabase.entryOf(c.name);
    final note = c.visaNote ?? VisaDatabase.noteOf(c.name);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              c.flag,
              height: 120,
              fit: BoxFit.contain,
              semanticLabel: "${c.name} bayrağı",
              errorBuilder: (_, __, ___) => const Icon(
                Icons.flag,
                size: 60,
                color: Color(0xFF7FA6D6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            c.name,
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
          infoCard("Başkent", c.capital),
          infoCard("Bölge", Labels.region(c.region)),
          infoCard("Nüfus", c.populationText),
          infoCard("Diller", c.languagesText),
          infoCard("Para birimi", c.currencyText),
          infoCard("TL karşılığı", _tryRateText,
              valueColor: Colors.greenAccent),
          infoCard("Saat dilimi", c.timezonesText),

          if (visa != null)
            infoCard("Vize", Labels.visa(visa),
                valueColor: _visaColor(visa)),
          if (entry != null) infoCard("Giriş", Labels.entry(entry)),

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
