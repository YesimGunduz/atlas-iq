import 'package:flutter/material.dart';
import 'package:globeinfo/widgets/footer.dart';
import 'countryservices.dart';
import 'savedpages.dart';
import 'widgets/saved_data.dart';

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

    if (oldWidget.query != widget.query) {
      fetchCountry();
    }
  }

  Future fetchCountry() async {
    setState(() {
      isLoading = true;
    });

    final data = await CountryService.getCountry(widget.query);

    if (data != null) {
      final currencies = data["currencies"];

      // 💱 TRY RATE
      if (currencies != null) {
        final code = currencies.keys.first;

        tryRate = await CountryService.getTryRate(code);
      }

      // 🕒 TIME DIFFERENCE (BASİT VE DOĞRU)
      final zones = data["timezones"];

      if (zones != null && zones.isNotEmpty) {
        final countryOffset = _extractOffset(zones[0]);

        const turkeyOffset = 3;

        final diff = countryOffset - turkeyOffset;

        if (diff > 0) {
          timeDifference = "+$diff saat Türkiye'den ileri";
        } else if (diff < 0) {
          timeDifference = "${diff.abs()} saat Türkiye'den geri";
        } else {
          timeDifference = "Türkiye ile aynı saat";
        }
      }
    }

    setState(() {
      country = data;
      isLoading = false;
    });
  }

  int _extractOffset(String timezone) {
    final match = RegExp(r'UTC([+-]\d{1,2})').firstMatch(timezone);

    if (match == null) return 0;

    return int.parse(match.group(1)!);
  }

  int _getCountryOffset() {
    try {
      final zones = country?["timezones"];

      if (zones == null || zones.isEmpty) return 0;

      final zone = zones[0]; // örnek: UTC+02:00

      final match = RegExp(r'UTC([+-]\d{1,2})').firstMatch(zone);

      if (match == null) return 0;

      return int.parse(match.group(1)!);
    } catch (e) {
      return 0;
    }
  }

  String getCurrency() {
    try {
      final currencies = country?['currencies'];

      if (currencies == null) return "-";

      final key = currencies.keys.first;

      return "$key (${currencies[key]['name']})";
    } catch (e) {
      return "-";
    }
  }

  String getTimezone() {
    try {
      final zones = country?['timezones'];

      if (zones == null) return "-";

      return (zones as List).join(", ");
    } catch (e) {
      return "-";
    }
  }

  Widget infoCard(String title, String value) {
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: title == "TRY Value" ? Colors.greenAccent : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dualLiveClock() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final nowUtc = DateTime.now().toUtc();

        // 🇹🇷 Türkiye (UTC+3)
        final turkey = nowUtc.add(const Duration(hours: 3));

        // 🌍 ÜLKE (offset dinamik)
        final countryOffset = _getCountryOffset();
        final countryTime = nowUtc.add(Duration(hours: countryOffset));

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const Text(
                    "TURKEY",
                    style: TextStyle(color: Color(0xFF7FA6D6), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    format(turkey),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              Column(
                children: [
                  const Text(
                    "COUNTRY",
                    style: TextStyle(color: Color(0xFF7FA6D6), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    format(countryTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8FB3DA),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162440),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162440),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF8FB3DA)),
        title: Text(
          widget.query,
          style: const TextStyle(
            color: Color(0xFF8FB3DA),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : country == null
          ? const Center(
              child: Text(
                "Country not found",
                style: TextStyle(color: Colors.white),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFF162440)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Image.network(
                            country!['flags']['png'],
                            width: 140,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            country!['name']['common'] ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isSaved = !isSaved;

                                final name = country?['name']['common'] ?? "";

                                if (isSaved) {
                                  if (!SavedData.savedCountries.contains(
                                    name,
                                  )) {
                                    SavedData.savedCountries.add(name);
                                  }
                                } else {
                                  SavedData.savedCountries.remove(name);
                                }
                              });
                            },
                            child: Icon(
                              isSaved ? Icons.star : Icons.star_border,
                              color: const Color.fromARGB(255, 235, 249, 81),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    sectionTitle("LIVE CLOCK"),

                    dualLiveClock(),
                    sectionTitle("BASIC INFO"),
                    infoCard("Capital", country!['capital']?[0] ?? "-"),
                    infoCard("Region", country!['region'] ?? "-"),
                    infoCard("Population", country!['population'].toString()),

                    sectionTitle("FINANCIAL INFO"),
                    infoCard("Currency", getCurrency()),
                    infoCard("TRY Value", tryRate),

                    sectionTitle("TIME INFO"),
                    infoCard("Timezone", getTimezone()),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SizedBox(height: 80, child: HomeFooter()),
    );
  }
}
