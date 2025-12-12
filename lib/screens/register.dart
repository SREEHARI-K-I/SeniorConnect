import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/login.dart';
import 'package:senior_citizen_app/screens/otp_verification.dart';
import 'package:senior_citizen_app/screens/volunregister.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final panchayatController = TextEditingController();
  final wardController = TextEditingController();
  final houseController = TextEditingController();
  final healthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// FULL NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 15),

            /// AGE
            TextField(
              controller: ageController,
              decoration: const InputDecoration(labelText: "Age"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            /// PHONE NUMBER
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),

            /// PANCHAYAT
            TextField(
              controller: panchayatController,
              decoration: const InputDecoration(labelText: "Panchayat"),
            ),
            const SizedBox(height: 15),

            /// WARD NUMBER
            TextField(
              controller: wardController,
              decoration: const InputDecoration(labelText: "Ward Number"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            /// HOUSE NUMBER
            TextField(
              controller: houseController,
              decoration: const InputDecoration(labelText: "House Number"),
            ),
            const SizedBox(height: 15),

            /// HEALTH ISSUES
            TextField(
              controller: healthController,
              decoration: const InputDecoration(
                labelText: "Health Issues (if any)",
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 30),

            /// REGISTER BUTTON
            ElevatedButton(
              onPressed: () {
                if (phoneController.text.isNotEmpty &&
                    nameController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OTPVerificationScreen(
                        phone: phoneController.text.trim(),
                        fromLogin: false,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Register"),
            ),

            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VolunteerRegisterScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.blue),
              ),
              child: const Text(
                "Register as Volunteer",
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),

            /// GO TO LOGIN
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                "Already have an account? Login",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
