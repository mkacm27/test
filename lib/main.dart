import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart'; // This will be created in the next step

void main() {
  // Ensures that the Flutter app is properly initialized before running.
  // This is required for async operations before runApp(), like DB initialization.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope stores the state of all providers.
    // The entire application is wrapped in it so that widgets can listen to providers.
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Printing Transactions Manager',
      theme: ThemeData(
        // Using Material 3 design principles
        useMaterial3: true,
        // Define a color scheme based on a seed color for a cohesive look
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005A9C), // A professional blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF005A9C),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF005A9C),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF005A9C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
      debugShowCheckedModeBanner: false,
      // The home screen of the app, which will be built next.
      home: const HomeScreen(),
    );
  }
}
