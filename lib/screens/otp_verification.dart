import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:senior_citizen_app/screens/user.dart';
import 'package:senior_citizen_app/screens/pending.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  final bool fromLogin;

  const OTPVerificationScreen({
    super.key,
    required this.phone,
    required this.fromLogin,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final otpController = TextEditingController();

  Future<void> completeLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("loggedIn", true);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CitizenDashboard()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fromLogin ? "Login OTP" : "Verify OTP"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Enter OTP sent to ${widget.phone}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: otpController,
              decoration: const InputDecoration(labelText: "OTP"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                if (otpController.text == "1234") {
                  completeLogin();
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
