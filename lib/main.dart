import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TeachLinkApp());
}

class TeachLinkApp extends StatelessWidget {
  const TeachLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeachLink Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
