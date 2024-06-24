import 'package:flutter/material.dart';
import 'package:towbruh/pages/customer_profile.dart';
import 'package:towbruh/pages/home_page.dart';
import 'package:towbruh/pages/settings_page.dart';
import 'bottom_nav_bar.dart';

class NavBarScaffold extends StatefulWidget {
  final String userRole;

  const NavBarScaffold({Key? key, required this.userRole}) : super(key: key);

  @override
  _NavBarScaffoldState createState() => _NavBarScaffoldState();
}

class _NavBarScaffoldState extends State<NavBarScaffold> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions(String userRole) {
    return [
      HomePage(userRole: userRole),
      if (userRole == 'customer') CustomerProfilePage(),
      SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: _widgetOptions(widget.userRole).elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
