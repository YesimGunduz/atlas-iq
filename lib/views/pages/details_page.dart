import 'package:flutter/material.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/data/labels.dart';
import 'package:globeinfo/data/saved_data.dart';
import 'package:globeinfo/services/country_services.dart';
import 'package:globeinfo/services/visa_dataservice.dart';
import 'package:globeinfo/theme/app_colors.dart';
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
          backgroundColor: AppColors.surfaceCard,
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
  /// Bilgi satırlarını TEK bir kutuda, ince ayraçlarla gösterir.
  ///
  /// Önceden her satır ayrı bir kart, ayrı kenarlık, ayrı gölgeydi; on tane
  /// eşit ağırlıkta kutu yan yana durunca hiçbiri öne çıkmıyordu. Kenarlığı
  /// ve zemini artık gruba bir kez veriyoruz.
  Widget _infoGroup(List<_InfoRow> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rows[i].title,
                    style: const TextStyle(
                      color: AppColors.textLabel,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: rows[i].color ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Sayfanın asıl cevabı: bu ülkeye vizesiz gidilir mi?
  /// En üstte, büyük ve duruma göre renkli.
  Widget _visaHighlight(String? visa, String? entry, String? note) {
    final known = visa != null;
    final color = known ? AppColors.visa(visa) : AppColors.textMuted;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.65), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                known ? Icons.badge_outlined : Icons.help_outline,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "VİZE DURUMU",
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            known ? Labels.visa(visa) : "Kayıt yok",
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (known && entry != null) ...[
            const SizedBox(height: 4),
            Text(
              Labels.entry(entry),
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 14,
              ),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    color: AppColors.textLabel, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!known) ...[
            const SizedBox(height: 6),
            const Text(
              "Bu ülke vize veri dosyasında yok.",
              style: TextStyle(color: AppColors.textLabel, fontSize: 13),
            ),
          ],
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
            color: AppColors.surfaceSunken,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
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
            style: const TextStyle(color: AppColors.textLabel, fontSize: 12),
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

  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textAppBar),
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
        child: CircularProgressIndicator(color: AppColors.accent),
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
              const Icon(Icons.search_off, color: AppColors.textLabel, size: 40),
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
                color: AppColors.textLabel,
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

          // 1) Sayfanın asıl sorusu en üstte
          _visaHighlight(visa, entry, note),

          // 2) Canlı saat - ikinci en çok bakılan şey
          dualLiveClock(),

          // 3) Geri kalan bilgiler tek grupta, daha sakin
          _infoGroup([
            _InfoRow("Saat farkı", timeDifference),
            _InfoRow("Başkent", c.capital),
            _InfoRow("Bölge", Labels.region(c.region)),
            _InfoRow("Nüfus", c.populationText),
            _InfoRow("Diller", c.languagesText),
            _InfoRow("Para birimi", c.currencyText),
            _InfoRow("TL karşılığı", _tryRateText,
                color: Colors.greenAccent),
            _InfoRow("Saat dilimi", c.timezonesText),
          ]),

          if (visa != null && VisaDatabase.disclaimer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                "${VisaDatabase.passport} için. ${VisaDatabase.disclaimer}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDim,
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

/// Detay sayfasındaki tek bir bilgi satırı.
class _InfoRow {
  final String title;
  final String value;
  final Color? color;

  const _InfoRow(this.title, this.value, {this.color});
}
