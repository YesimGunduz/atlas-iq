import 'dart:async';

import 'package:flutter/material.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/data/country_names_tr.dart';
import 'package:globeinfo/data/labels.dart';
import 'package:globeinfo/services/country_services.dart';
import 'package:globeinfo/services/visa_dataservice.dart';
import 'package:globeinfo/services/visa_engine.dart';
import 'package:globeinfo/theme/app_colors.dart';
import 'package:globeinfo/views/pages/details_page.dart';
import 'package:globeinfo/views/pages/game_page.dart';
import 'package:globeinfo/views/widgets/country_card.dart';
import 'package:globeinfo/views/widgets/country_search_field.dart';
import 'package:globeinfo/views/widgets/data_notice.dart';
import 'package:globeinfo/views/widgets/filter_sheet.dart';
import 'package:globeinfo/views/widgets/footer.dart';
import 'package:globeinfo/views/widgets/header.dart';
import 'package:globeinfo/views/widgets/hero_card.dart';
import 'package:globeinfo/views/widgets/travel_mode_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// API'den gelen tam liste (hiç değişmez)
  List<Country> allCountries = [];

  /// Ekranda gösterilen liste (arama + filtre sonucu)
  List<Country> countries = [];

  bool isLoading = true;
  String? errorMessage;

  String? _visaFilter;
  String? _entryFilter;

  final List<String> _hints = [
    "Ülke ya da bayrak ara...",
    "Ülkeleri anlık olarak keşfet",
    "İstediğin ülkeyi hemen bul",
    "Güncel ülke bilgileri",
  ];

  int _hintIndex = 0;
  Timer? _hintTimer;

  bool _isActive = false;

  @override
  void initState() {
    super.initState();

    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
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

  // ---------------- YÜKLEME ----------------
  Future<void> loadCountries() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await VisaDatabase.load();

      final data = await CountryService.getAllCountries();
      VisaDatabase.attachTo(data);

      if (!mounted) return;

      setState(() {
        allCountries = data;
        isLoading = false;
      });

      _applyFilters();
      _refreshInBackground();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "$e";
      });
    }
  }

  /// Önbellekten gelen liste bayatsa sessizce yeniler.
  Future<void> _refreshInBackground() async {
    final changed = await CountryService.refreshIfStale();
    if (!changed || !mounted) return;

    try {
      final data = await CountryService.getAllCountries();
      VisaDatabase.attachTo(data);

      if (!mounted) return;
      setState(() => allCountries = data);
      _applyFilters();
    } catch (_) {
      // Tazeleme başarısızsa eldeki listeyle devam.
    }
  }

  // ---------------- ARAMA VE FİLTRE ----------------
  void _onQueryChanged() {
    // _isActive'i setState dışında güncelleyip tek yeniden çizime bırakıyoruz.
    _isActive = _searchCtrl.text.isNotEmpty || _focusNode.hasFocus;
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim();

    var result = VisaEngine.filterCountries(
      allCountries,
      _visaFilter,
      _entryFilter,
    );

    if (query.isNotEmpty) {
      result = result
          .where((c) => CountryNamesTr.matches(c.name, query))
          .toList();
    }

    setState(() => countries = result);
  }

  /// Arama kutusundaki oka / enter'a basınca detay sayfasını aç.
  void _onSearchSubmitted() {
    final query = _searchCtrl.text.trim();

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
            backgroundColor: AppColors.surface,
            content: Text(
              "\"$query\" ile eşleşen ülke yok",
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        );
      return;
    }

    // Liste hiç yüklenmediyse yazılanla doğrudan dene.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountryDetailPage(
          query: CountryNamesTr.resolve(query),
        ),
      ),
    );
  }

  void _openGame() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FlagGamePage()),
    );
  }

  void _openCountry(Country country) {
    if (country.name.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CountryDetailPage(query: country.name)),
    );
  }

  Future<void> openFilter() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
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

  /// Elimizdeki ülkelerde geçen benzersiz dil sayısı.
  int get _languageCount {
    final all = <String>{};
    for (final c in allCountries) {
      all.addAll(c.languages);
    }
    return all.length;
  }

  // ---------------- AKTİF FİLTRE SATIRI ----------------
  Widget _buildFilterBar() {
    if (_visaFilter == null && _entryFilter == null) {
      return const SizedBox.shrink();
    }

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
                  _filterChip(
                      Labels.visa(_visaFilter), AppColors.visa(_visaFilter)),
                if (_entryFilter != null)
                  _filterChip(
                      Labels.entry(_entryFilter), AppColors.accentLight),
              ],
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              "Temizle",
              style: TextStyle(color: AppColors.textSecondary),
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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------------- LİSTE ALANI ----------------
  Widget _buildResults() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (errorMessage != null) return _buildError();

    if (countries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            VisaEngine.emptyMessage(_visaFilter, _entryFilter),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: countries.length,
      itemBuilder: (_, index) => CountryCard(
        country: countries[index],
        onTap: () => _openCountry(countries[index]),
      ),
    );
  }

  Widget _buildError() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 12),
          const Text(
            "Veriler alınamadı",
            style: TextStyle(
              color: AppColors.textPrimary,
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
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Text(
                "Şu an demo API anahtarı kullanılıyor.\n"
                "restcountries.com'dan ücretsiz anahtar alıp uygulamayı "
                "şöyle başlat:\n\n"
                "flutter run --dart-define=RC_API_KEY=anahtarin",
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              errorMessage!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SAYFA ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeHeader(onPlay: _openGame),
            const SizedBox(height: 16),
            HeroCard(
              countryCount: allCountries.length,
              visaRuleCount: VisaDatabase.recordCount,
              languageCount: _languageCount,
              isLoading: isLoading,
            ),
            const SizedBox(height: 16),
            CountrySearchField(
              controller: _searchCtrl,
              focusNode: _focusNode,
              hint: _isActive ? "" : _hints[_hintIndex],
              onSubmit: _onSearchSubmitted,
            ),
            TravelModeCard(onTap: openFilter),
            DataNotice(loadedCount: allCountries.length),
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
