import 'package:flutter/material.dart';
import 'dart:async';
import 'homepage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [

        // 🌍 BACKGROUND
        Image.asset(
          "assets/splashatlas.png",
          fit: BoxFit.cover,
        ),

        // 🔲 OVERLAY
        Container(
          color: Colors.black.withOpacity(0.35),
        ),

        // ✨ CONTENT
        Column(
          children: [

            const Spacer(flex: 4),

            // 🔥 TITLE BLOCK
            Column(
              children: [

                const Text(
                  "AtlasIQ",
                  style: TextStyle(
                    fontSize: 30,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(blurRadius: 20, color: Color.fromARGB(255, 7, 33, 79)),
                      Shadow(blurRadius: 40, color: Color.fromARGB(110, 0, 0, 0)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 300),

            // 📄 DESCRIPTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Explore global countries, flags, and key statistics in real time",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(255, 249, 249, 249),
                  fontSize: 16,
                   shadows: [
                      Shadow(blurRadius: 20, color: Color.fromARGB(255, 7, 33, 79)),
                      Shadow(blurRadius: 40, color: Color.fromARGB(110, 0, 0, 0)),
                    ],
                ),
              ),
            ),

            const Spacer(flex: 3),

            // ⏳ LOADING (BOTTOM FIXED FEEL)
            const CircularProgressIndicator(
              color: Color.fromARGB(255, 255, 255, 255),
              strokeWidth: 2,
            ),

            const SizedBox(height: 10),

            const Text(
              "Loading world data...",
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 14,
                 shadows: [
                      Shadow(blurRadius: 20, color: Color.fromARGB(255, 7, 33, 79)),
                      Shadow(blurRadius: 40, color: Color.fromARGB(110, 0, 0, 0)),
                    ],
              ),
            ),

            const Spacer(flex: 1),
          ],
        ),
      ],
    ),
  );
}}