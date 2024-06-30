import 'package:flutter/material.dart';
import 'package:towbruh/pages/cust_home.dart';
import 'package:towbruh/pages/driver_home.dart';
import 'package:towbruh/message/message_page.dart';
import 'package:towbruh/pages/profile_page.dart';

class NavBarScaffold extends StatefulWidget {
  final String userRole;

  const NavBarScaffold({Key? key, required this.userRole}) : super(key: key);

  @override
  _NavBarScaffoldState createState() => _NavBarScaffoldState();
}

class _NavBarScaffoldState extends State<NavBarScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget homePage;
    if (widget.userRole == 'customer') {
      homePage = CustomerHomePage();
    } else if (widget.userRole == 'tow') {
      homePage = DriverHomePage();
    } else {
      // Handle any other roles if necessary
      homePage = Container(); // Placeholder for other roles
    }

    List<Widget> pages = [
      homePage,
      MessagePage(),
      ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
