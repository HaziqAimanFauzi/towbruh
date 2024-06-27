import 'package:flutter/material.dart';
import 'package:towbruh/pages/home_page.dart';
import 'package:towbruh/pages/message_page.dart';
import 'package:towbruh/pages/settings_page.dart';
import 'package:towbruh/pages/profile_page.dart'; // Updated import for ProfilePage

class NavBarScaffold extends StatefulWidget {
  final String userRole;

  const NavBarScaffold({Key? key, required this.userRole}) : super(key: key);

  @override
  _NavBarScaffoldState createState() => _NavBarScaffoldState();
}

class _NavBarScaffoldState extends State<NavBarScaffold> {
  int _selectedIndex = 0;

  List<Widget> _widgetOptions(String userRole) {
    return [
      HomePage(userRole: userRole),
      MessagePage(),
      ProfilePage(), // Using ProfilePage instead of CustomerProfilePage or TowProfilePage
      SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: _widgetOptions(widget.userRole).elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
        selectedFontSize: 14.0,
        unselectedFontSize: 12.0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }
}
