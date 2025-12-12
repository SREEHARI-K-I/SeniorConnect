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
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final wardController = TextEditingController();
  final panchayatController = TextEditingController();
  final occupationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Volunteer Registration"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

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
              controller: nameController,
              decoration: const InputDecoration(labelText: "Age"),
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
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Occupation"),
            ),
            const SizedBox(height: 15),

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
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Register",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
