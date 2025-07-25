// main.dart
import 'package:flutter/material.dart';
import 'admin_dashboard.dart';

void main() {
  runApp(const TiffinAdminApp());
}

class TiffinAdminApp extends StatelessWidget {
  const TiffinAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiffin Admin',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AdminDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}