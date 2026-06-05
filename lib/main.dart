import 'package:flutter/material.dart';
import 'splashpage.dart';
import 'homepage.dart';
import 'detailspage.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:  SplashScreen(),
        routes: {
        '/detail': (context) {
          final query =
              ModalRoute.of(context)!.settings.arguments as String;

          return CountryDetailPage(query: query);
        },
        },
    );
  }
}
