import 'package:flutter/material.dart';
import 'package:towbruh/pages/role_selection.dart';
import '../pages/login.dart';
import '../pages/register.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;
  String selectedRole = '';

  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  void selectRole(String role) {
    setState(() {
      selectedRole = role;
      showLoginPage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedRole.isEmpty) {
      return RoleSelectionPage(
        onRoleSelected: selectRole,
      );
    } else if (showLoginPage) {
      return LoginPage(showRegisterPage: toggleScreens, selectedRole: selectedRole);
    } else {
      return RegisterPage(showLoginPage: toggleScreens, selectedRole: selectedRole);
    }
  }
}
