import 'package:flutter/material.dart';

class RoleSelectionPage extends StatelessWidget {
  final Function(String) onRoleSelected;

  const RoleSelectionPage({Key? key, required this.onRoleSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 100,
              ),
              SizedBox(height: 75),
              Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () => onRoleSelected('customer'),
                child: Text('Customer'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => onRoleSelected('tow_driver'),
                child: Text('Tow Driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
