import 'package:flutter/material.dart';
import '../pages/login.dart';
import '../pages/register.dart';
import '../pages/role_selection.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;
  String? selectedRole;

  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  void onRoleSelected(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedRole == null) {
      return RoleSelectionPage(onRoleSelected: onRoleSelected);
    } else {
      return showLoginPage
          ? LoginPage(selectedRole: selectedRole!)
          : RegisterPage(
        selectedRole: selectedRole!,
        showLoginPage: toggleScreens,
      );
    }
  }
}
