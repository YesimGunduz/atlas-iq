import 'dart:async';

import 'package:flutter/material.dart';
import 'package:globeinfo/data/country.dart';
import 'package:globeinfo/data/country_names_tr.dart';
import 'package:globeinfo/i18n/locale_controller.dart';
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

  int _hintIndex = 0;
  Timer? _hintTimer;

  bool _isActive = false;

  @override
  void initState() {
    super.initState();

    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % S.searchHints.length);
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
              S.noSearchMatch(query),
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
                      S.visaLabel(_visaFilter), AppColors.visa(_visaFilter)),
                if (_entryFilter != null)
                  _filterChip(
                      S.entryLabel(_entryFilter), AppColors.accentLight),
              ],
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              S.clear,
              style: const TextStyle(color: AppColors.textSecondary),
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

    if (countries.isEmpty) return _buildEmpty();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: countries.length,
      itemBuilder: (_, index) => CountryCard(
        country: countries[index],
        onTap: () => _openCountry(countries[index]),
      ),
    );
  }

  /// Liste neden boş? Üç ayrı sebep var ve kullanıcıya hangisi olduğunu
  /// söylemek gerekiyor; hepsine "Ülke bulunamadı" demek yardımcı değil.
  Widget _buildEmpty() {
    final query = _searchCtrl.text.trim();
    final hasFilter = _visaFilter != null || _entryFilter != null;

    String title;
    String? detail;
    IconData icon;

    if (allCountries.isEmpty) {
      icon = Icons.cloud_off;
      title = S.emptyListTitle;
      detail = S.emptyListDetail;
    } else if (query.isNotEmpty && hasFilter) {
      icon = Icons.search_off;
      title = S.emptyFilteredSearch(query);
      detail = S.clearFilter;
    } else if (query.isNotEmpty) {
      icon = Icons.search_off;
      title = S.emptySearchTitle(query);
      detail = S.emptySearchDetail;
    } else {
      icon = Icons.filter_alt_off;
      title = VisaEngine.emptyMessage(_visaFilter, _entryFilter);
      detail = S.emptyFilterDetail(allCountries.length);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (allCountries.isEmpty)
              ElevatedButton.icon(
                onPressed: loadCountries,
                icon: const Icon(Icons.refresh),
                label: Text(S.tryAgain),
              )
            else if (hasFilter)
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: Text(S.clearFilter),
              )
            else if (query.isNotEmpty)
              TextButton.icon(
                onPressed: _searchCtrl.clear,
                icon: const Icon(Icons.close),
                label: Text(S.clearSearch),
              ),
          ],
        ),
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
          Text(
            S.loadFailed,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: loadCountries,
            icon: const Icon(Icons.refresh),
            label: Text(S.tryAgain),
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
              child: Text(
                S.demoKeyWarning,
                style: const TextStyle(
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
              hint: _isActive ? "" : S.searchHints[_hintIndex],
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
