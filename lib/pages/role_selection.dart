import 'package:flutter/material.dart';

class RoleSelectionPage extends StatelessWidget {
  final Function(String) onRoleSelected;

  const RoleSelectionPage({Key? key, required this.onRoleSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Your Role'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                onRoleSelected('customer');
              },
              child: Text('Customer'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                onRoleSelected('tow_driver');
              },
              child: Text('Tow Driver'),
            ),
          ],
        ),
      ),
    );
  }
}
