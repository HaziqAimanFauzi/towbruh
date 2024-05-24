import 'package:flutter/material.dart';
import 'package:towbruh/pages/customer_profile.dart';
import 'package:towbruh/pages/home_page.dart';
import 'package:towbruh/pages/settings_page.dart';
import 'package:towbruh/pages/tow_profile.dart';

class NavBarScaffold extends StatefulWidget {
  final String userRole; // Add this line

  const NavBarScaffold({Key? key, required this.userRole}) : super(key: key); // Add this constructor

  @override
  _NavBarScaffoldState createState() => _NavBarScaffoldState();
}

class _NavBarScaffoldState extends State<NavBarScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(userRole: 'customer',),
    // Placeholder for Profile Page, will be replaced dynamically
    SizedBox.shrink(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 1
          ? (widget.userRole == 'customer' ? CustomerProfilePage() : TowProfilePage()) // Update this line
          : _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
