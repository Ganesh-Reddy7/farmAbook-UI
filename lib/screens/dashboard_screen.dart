import 'package:flutter/material.dart';
import '../widgets/frosted_card.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  DashboardScreen({required this.onToggleTheme});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Map<String, String>> cardData = [
    {'title': 'Profit/Loss', 'value': '₹12,500'},
    {'title': 'Investments', 'value': '₹75,000'},
    {'title': 'Returns', 'value': '₹8,200'},
    {'title': 'Expenses', 'value': '₹3,500'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "FarmAbook",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.person),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          )
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Horizontal Scroll Cards
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cardData.length,
                separatorBuilder: (context, index) => SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return FrostedCard(
                    title: cardData[index]['title']!,
                    value: cardData[index]['value']!,
                  );
                },
              ),
            ),
          ),

          // Tabs Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                Center(child: Text("📊 Summary View")),
                Center(child: Text("➕ Add Investment Form")),
                Center(child: Text("💰 Add Return Form")),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Summary"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Add Investment"),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Add Return"),
        ],
      ),
    );
  }
}
