import 'package:flutter/material.dart';

import 'package:flutter_pos_background_upload_download/features/auth/presentation/splash_screen.dart';

class QuickDrop extends StatelessWidget {
  const QuickDrop({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickDrop',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF56A76A),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF183B25)),
          bodyMedium: TextStyle(color: Color(0xFF31543B)),
          titleMedium: TextStyle(color: Color(0xFF183B25)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: .8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB7D9BE)),
          ),
        ),
      ),
      home: const SplashScreen(),
      builder: (context, child) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE7F5E9)],
          ),
        ),
        child: child,
      ),
    );
  }
}
