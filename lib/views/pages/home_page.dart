import 'dart:async';

import 'package:flutter/material.dart';
import 'package:globeinfo/data/country_names_tr.dart';
import 'package:globeinfo/services/country_services.dart';
import 'package:globeinfo/services/visa_dataservice.dart';
import 'package:globeinfo/services/visa_engine.dart';
import 'package:globeinfo/views/pages/details_page.dart';
import 'package:globeinfo/views/widgets/filter_sheet.dart';
import 'package:globeinfo/views/widgets/footer.dart';
import 'package:globeinfo/views/widgets/header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ---------------- STAT BOX ----------------
class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8AA4C2), fontSize: 11),
        ),
      ],
    );
  }
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// API'den gelen tam liste (hiç değişmez)
  List<Map<String, dynamic>> allCountries = [];

  /// Ekranda gösterilen liste (arama + filtre sonucu)
  List<Map<String, dynamic>> countries = [];

  bool isLoading = true;
  String? errorMessage;

  String? _visaFilter;
  String? _entryFilter;

  final List<String> _hints = [
    "Search country or flag...",
    "Discover countries in real time",
    "Search any country instantly",
    "Get live country data",
  ];

  int _hintIndex = 0;
  String _currentHint = "";
  Timer? _hintTimer;

  bool _isActive = false;

  @override
  void initState() {
    super.initState();

    _currentHint = _hints[_hintIndex];

    _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _hintIndex = (_hintIndex + 1) % _hints.length;
        _currentHint = _hints[_hintIndex];
      });
    });

    _searchCtrl.addListener(_onQueryChanged);
    _focusNode.addListener(_onQueryChanged);

    loadCountries();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  // ---------------- LOAD ----------------
  Future<void> loadCountries() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await VisaDatabase.load();

      final data = await CountryService.getAllCountries();
      VisaDatabase.attachTo(data, CountryService.countryName);

      if (!mounted) return;

      setState(() {
        allCountries = data;
        isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "$e";
      });
    }
  }

  // ---------------- SEARCH + FILTER ----------------
  void _onQueryChanged() {
    setState(() {
      _isActive = _searchCtrl.text.isNotEmpty || _focusNode.hasFocus;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();

    var result = VisaEngine.filterCountries(
      allCountries,
      _visaFilter,
      _entryFilter,
    );

    if (query.isNotEmpty) {
      result = result
          .where(
            (c) => CountryNamesTr.matches(CountryService.countryName(c), query),
          )
          .toList();
    }

    setState(() => countries = result);
  }

  /// Arama kutusundaki oka / enter'a basınca detay sayfasını aç.
  void _onSearchSubmitted() {
    final query = _searchCtrl.text.trim();

    // Eşleşme varsa ilkini aç.
    if (countries.isNotEmpty) {
      _openCountry(countries.first);
      return;
    }

    if (query.isEmpty) return;

    // Liste yüklü ama eşleşme yok -> boş bir detay sayfası açmanın anlamı yok.
    if (allCountries.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF162440),
            content: Text(
              "\"$query\" ile eşleşen ülke yok",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      return;
    }

    // Liste hiç yüklenmediyse (bağlantı hatası) yazılanla doğrudan dene.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountryDetailPage(
          query: CountryNamesTr.resolve(query),
        ),
      ),
    );
  }

  void _openCountry(Map<String, dynamic> country) {
    final name = CountryService.countryName(country);
    if (name.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CountryDetailPage(query: name)),
    );
  }

  // ---------------- FILTER SHEET ----------------
  Future<void> openFilter() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628),
      builder: (_) => const FilterSheet(),
    );

    if (result == null) return;

    _visaFilter = result["visa"] as String?;
    _entryFilter = result["entry"] as String?;

    _applyFilters();
  }

  void _clearFilters() {
    _visaFilter = null;
    _entryFilter = null;
    _applyFilters();
  }

  // ---------------- HERO ----------------
  Widget _buildHeroCard() {
    final countryCount = allCountries.isEmpty ? "195" : "${allCountries.length}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF121B2E), Color(0xFF172238)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x334F8CFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.explore, color: Color(0xFF3B82F6), size: 20),
                SizedBox(width: 10),
                Text(
                  "Explore The World",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Discover countries, flags, languages with live data",
              style: TextStyle(color: Color(0xFF9DB2CE), fontSize: 13),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatBox(
                  icon: Icons.public,
                  value: countryCount,
                  label: "Countries",
                ),
                _StatBox(
                  icon: Icons.card_travel,
                  value: "${VisaDatabase.recordCount}",
                  label: "Visa Rules",
                ),
                const _StatBox(
                  icon: Icons.language,
                  value: "7000+",
                  label: "Languages",
                ),
                _StatBox(
                  icon: Icons.flash_on,
                  value: isLoading ? "..." : "LIVE",
                  label: "Data",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SEARCH BAR ----------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF162440),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search, color: Color(0xFF7A9CC4)),
            ),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _onSearchSubmitted(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: _isActive ? "" : _currentHint,
                  hintStyle: const TextStyle(color: Color(0xFF7A9CC4)),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF7A9CC4), size: 18),
                onPressed: () => _searchCtrl.clear(),
              ),
            SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _onSearchSubmitted,
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ---------------- SMART CARD ----------------
  Widget _buildSmartCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 75, 131, 168),
              Color.fromARGB(255, 175, 184, 190),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.public, color: Colors.black),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Smart Travel Mode",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Discover visa, passport & ID options",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: openFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF073559),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Explore Rules",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- AKTİF FİLTRE SATIRI ----------------
  Widget _buildFilterBar() {
    final hasFilter = _visaFilter != null || _entryFilter != null;
    if (!hasFilter) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_visaFilter != null)
                  _filterChip(_visaFilter!, visaColor(_visaFilter!)),
                if (_entryFilter != null)
                  _filterChip(_entryFilter!, const Color(0xFF4DA3FF)),
              ],
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              "Temizle",
              style: TextStyle(color: Color(0xFF8AA4C2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  static Color visaColor(String? v) {
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
        return const Color(0xFF7A9CC4);
    }
  }

  // ---------------- VERİ EKSİK UYARISI ----------------
  /// Demo anahtarı örnek veri döndürüyorsa ya da API'nin bildirdiği toplam
  /// sayıdan az ülke geldiyse kullanıcıya sebebini söyle.
  Widget _buildDataNotice() {
    if (isLoading || errorMessage != null || allCountries.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = CountryService.reportedTotal;
    final incomplete = total != null && allCountries.length < total;

    if (!CountryService.demoResponseDetected && !incomplete) {
      return const SizedBox.shrink();
    }

    final countText = total != null
        ? "${allCountries.length} / $total ülke yüklendi"
        : "${allCountries.length} ülke yüklendi";

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1AFFA502),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x66FFA502)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                color: Color(0xFFFFA502), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    countText,
                    style: const TextStyle(
                      color: Color(0xFFFFA502),
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
                        : "API tam listeyi döndürmedi. Tekrar denemek için "
                            "aşağı çekip bırak.",
                    style: const TextStyle(
                      color: Color(0xFFD6A45A),
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

  // ---------------- ÜLKE KARTI ----------------
  Widget _countryCard(Map<String, dynamic> country) {
    final name = CountryService.countryName(country);
    final capital = CountryService.capitalOf(country);
    final flag = CountryService.flagUrl(country);
    final visa = country["visa"]?.toString();

    return InkWell(
      onTap: () => _openCountry(country),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF122038),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF223B5E)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                flag,
                width: 48,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 34,
                  color: const Color(0xFF223B5E),
                  child: const Icon(
                    Icons.flag,
                    size: 16,
                    color: Color(0xFF7A9CC4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    capital,
                    style: const TextStyle(
                      color: Color(0xFF8AA4C2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (visa != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: visaColor(visa).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: visaColor(visa)),
                ),
                child: Text(
                  visa,
                  style: TextStyle(color: visaColor(visa), fontSize: 10),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF7A9CC4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- LİSTE ALANI ----------------
  Widget _buildResults() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    if (errorMessage != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.cloud_off, color: Color(0xFF7A9CC4), size: 40),
            const SizedBox(height: 12),
            const Text(
              "Veriler alınamadı",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loadCountries,
              icon: const Icon(Icons.refresh),
              label: const Text("Tekrar dene"),
            ),
            if (CountryService.isUsingDemoKey)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFA502),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFA502)),
                ),
                child: const Text(
                  "Şu an demo API anahtarı kullanılıyor.\n"
                  "restcountries.com'dan ücretsiz anahtar alıp uygulamayı "
                  "şöyle başlat:\n\n"
                  "flutter run --dart-define=RC_API_KEY=anahtarin",
                  style: TextStyle(
                    color: Color(0xFFFFA502),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Teknik detay - hatayı bulmak için
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF122038),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF223B5E)),
              ),
              child: SelectableText(
                errorMessage!,
                style: const TextStyle(
                  color: Color(0xFF8AA4C2),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (countries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            VisaEngine.emptyMessage(_visaFilter, _entryFilter),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8AA4C2)),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: countries.length,
      itemBuilder: (_, index) => _countryCard(countries[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HomeHeader(),
            const SizedBox(height: 16),
            _buildHeroCard(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            _buildSmartCard(),
            _buildDataNotice(),
            _buildFilterBar(),
            const SizedBox(height: 4),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
      bottomNavigationBar: const HomeFooter(currentIndex: 0),
    );
  }
}
