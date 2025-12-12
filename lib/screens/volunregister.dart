import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/otp_verification.dart';

class VolunteerRegisterScreen extends StatefulWidget {
  const VolunteerRegisterScreen({super.key});

  @override
  State<VolunteerRegisterScreen> createState() =>
      _VolunteerRegisterScreenState();
}

class _VolunteerRegisterScreenState extends State<VolunteerRegisterScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final wardController = TextEditingController();
  final panchayatController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Volunteer Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: panchayatController,
              decoration: const InputDecoration(labelText: "Panchayat"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: wardController,
              decoration: const InputDecoration(labelText: "Ward Number"),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                if (phoneController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OTPVerificationScreen(
                        phone: phoneController.text.trim(),
                        fromLogin: false,
                        // Mark as volunteer registration
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Register as Volunteer"),
            ),
          ],
        ),
      ),
    );
  }
}
