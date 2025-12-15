import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("farmAbook_cache");
  await dotenv.load(fileName: ".env");

  runApp(
    const ProviderScope(
      child: FarmAbookApp(),
    ),
  );
}

class FarmAbookApp extends StatefulWidget {
  const FarmAbookApp({super.key});

  @override
  _FarmAbookAppState createState() => _FarmAbookAppState();
}

class _FarmAbookAppState extends State<FarmAbookApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmAbook',

      // -------------------------------
      // 🔒 LOCK SYSTEM FONT SCALING
      // -------------------------------
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaleFactor: 1.0, // 🔥 Prevent system font scaling
          ),
          child: child!,
        );
      },

      // -------------------------------
      // 🌞 LIGHT THEME
      // -------------------------------
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        fontFamily: "Roboto", // Optional global font
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87, fontSize: 13),
          titleMedium: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),

      // -------------------------------
      // 🌚 DARK THEME
      // -------------------------------
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        fontFamily: "Roboto",
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.grey, fontSize: 13),
          titleMedium: TextStyle(color: Colors.white, fontSize: 18),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade900,
        ),
      ),

      themeMode: _themeMode,

      // -------------------------------
      // 🚀 SPLASH SCREEN
      // -------------------------------
      home: SplashScreen(
        toggleTheme: _toggleTheme,
      ),
    );
  }
}
