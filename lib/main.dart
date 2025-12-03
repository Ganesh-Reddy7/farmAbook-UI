import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  // await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  runApp(FarmAbookApp());
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

  bool isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmAbook',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87, fontSize: 13),
          titleMedium: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.grey, fontSize: 13),
          titleMedium: TextStyle(color: Colors.white, fontSize: 18),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade900,
        ),
      ),
      themeMode: _themeMode,
      home: SplashScreen(
        toggleTheme: _toggleTheme,
      ),
    );
  }
}



