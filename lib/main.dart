// import 'package:flutter/material.dart';
// import 'dart:ui'; // required for frosted glass effect
//
// void main() {
//   runApp(FarmAbookApp());
// }
//
// class FarmAbookApp extends StatefulWidget {
//   @override
//   _FarmAbookAppState createState() => _FarmAbookAppState();
// }
//
// class _FarmAbookAppState extends State<FarmAbookApp> {
//   ThemeMode _themeMode = ThemeMode.light;
//
//   void _toggleTheme() {
//     setState(() {
//       _themeMode =
//       _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'FarmAbook',
//       theme: ThemeData(
//         brightness: Brightness.light,
//         primarySwatch: Colors.green,
//       ),
//       darkTheme: ThemeData(
//         brightness: Brightness.dark,
//         primarySwatch: Colors.green,
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.green.shade900,
//         ),
//       ),
//       themeMode: _themeMode,
//       home: DashboardScreen(onToggleTheme: _toggleTheme),
//     );
//   }
// }
//
// class DashboardScreen extends StatefulWidget {
//   final VoidCallback onToggleTheme;
//   DashboardScreen({required this.onToggleTheme});
//
//   @override
//   _DashboardScreenState createState() => _DashboardScreenState();
// }
//
// class _DashboardScreenState extends State<DashboardScreen>
//     with SingleTickerProviderStateMixin {
//   int _selectedIndex = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     bool isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Center(
//           child: Text(
//             "FarmAbook",
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//         ),
//         leading: IconButton(
//           icon: Icon(Icons.person),
//           onPressed: () {},
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.brightness_6),
//             onPressed: widget.onToggleTheme,
//           )
//         ],
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           // Horizontally scrollable row of cards
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//             child: SizedBox(
//               height: 90,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: [
//                   SizedBox(width: 8),
//                   _buildFrostedCard("Profit/Loss", "₹0"),
//                   SizedBox(width: 12),
//                   _buildFrostedCard("Investments", "₹0"),
//                   SizedBox(width: 12),
//                   _buildFrostedCard("Returns", "₹0"),
//                   SizedBox(width: 12),
//                   _buildFrostedCard("Expenses", "₹0"), // additional example
//                   SizedBox(width: 8),
//                 ],
//               ),
//             ),
//           ),
//
//           // Tab content
//           Expanded(
//             child: IndexedStack(
//               index: _selectedIndex,
//               children: [
//                 Center(child: Text("📊 Summary View")),
//                 Center(child: Text("➕ Add Investment Form")),
//                 Center(child: Text("💰 Add Return Form")),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) => setState(() => _selectedIndex = index),
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Summary"),
//           BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Add Investment"),
//           BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Add Return"),
//         ],
//       ),
//     );
//   }
//
//   // Frosted glass compact card with tap/scale animation
//   Widget _buildFrostedCard(String title, String value) {
//     bool isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Container(
//       width: MediaQuery.of(context).size.width * 0.38, // wider card
//       padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16), // less vertical padding
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(14),
//         gradient: LinearGradient(
//           colors: isDark
//               ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
//               : [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.02)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         border: Border.all(
//           color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
//             blurRadius: 15,
//             spreadRadius: 2,
//             offset: Offset(0, 5),
//           ),
//           BoxShadow(
//             color: isDark ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1),
//             blurRadius: 10,
//             spreadRadius: 1,
//             offset: Offset(-3, -3),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(14),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 13,
//                   color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
//                 ),
//               ),
//               SizedBox(height: 4), // slightly reduced spacing
//               Text(
//                 value,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
// }

import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'splash_screen.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  // await dotenv.load(fileName: ".env");
  runApp(FarmAbookApp());
}

class FarmAbookApp extends StatefulWidget {
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

  // ✅ later you’ll replace this with real login check
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
        isLoggedIn: isLoggedIn,
        toggleTheme: _toggleTheme,
      ),
    );
  }
}



