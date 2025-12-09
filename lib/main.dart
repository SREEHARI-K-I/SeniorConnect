import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user already registered
  final prefs = await SharedPreferences.getInstance();
  bool isRegistered = prefs.getBool('isRegistered') ?? false;

  runApp(MyApp(isRegistered: isRegistered));
}

class MyApp extends StatelessWidget {
  final bool isRegistered;

  const MyApp({super.key, required this.isRegistered});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SeniorConnect",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      // SplashScreen runs first → then redirects based on isRegistered
      home: SplashScreen(isRegistered: isRegistered),
    );
  }
}
