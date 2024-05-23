import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

class NavBarScaffold extends StatefulWidget {
  final int initialIndex;
  final List<Widget> pages;

  const NavBarScaffold({
    Key? key,
    required this.initialIndex,
    required this.pages,
  }) : super(key: key);

  @override
  _NavBarScaffoldState createState() => _NavBarScaffoldState();
}

class _NavBarScaffoldState extends State<NavBarScaffold> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
