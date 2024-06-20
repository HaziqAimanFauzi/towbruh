import 'package:flutter/material.dart';
import 'package:towbruh/pages/customer_profile.dart'; // Import your customer profile page
import 'package:towbruh/pages/tow_profile.dart'; // Import your tow profile page
import 'package:towbruh/settings_page.dart'; // Import your settings page

class HomePage extends StatefulWidget {
  final String userRole;

  const HomePage({Key? key, required this.userRole}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptionsCustomer = [
    const Text('Home Page Content'), // Replace with your home page content
    CustomerProfilePage(), // Replace with your customer profile page
    const SettingsPage(),
  ];

  final List<Widget> _widgetOptionsTow = [
    const Text('Home Page Content'), // Replace with your home page content
    TowProfilePage(), // Replace with your tow profile page
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: widget.userRole == 'customer'
            ? _widgetOptionsCustomer.elementAt(_selectedIndex)
            : _widgetOptionsTow.elementAt(_selectedIndex),
      ),
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
