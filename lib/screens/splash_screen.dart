import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/admin.dart';
import 'package:senior_citizen_app/screens/register.dart';
import 'package:senior_citizen_app/screens/user.dart';
import 'package:senior_citizen_app/screens/volunteer.dart';
import 'package:senior_citizen_app/screens/ambulance.dart';
import 'package:senior_citizen_app/services/api_service.dart';
import 'package:senior_citizen_app/services/push_notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 2));

    final loggedIn = await ApiService.isLoggedIn();
    final role = await ApiService.getRole();

    if (!mounted) return;

    if (!loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
      return;
    }

    if (role == 'admin') {
      await PushNotificationService.syncVolunteerDeviceToken();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else if (role == 'volunteer') {
      await PushNotificationService.syncVolunteerDeviceToken();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VolunteerDashboard()),
      );
    } else if (role == 'ambulance') {
      await PushNotificationService.syncVolunteerDeviceToken();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AmbulanceDashboard()),
      );
    } else {
      await PushNotificationService.syncVolunteerDeviceToken();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CitizenDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'SeniorConnect',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}
