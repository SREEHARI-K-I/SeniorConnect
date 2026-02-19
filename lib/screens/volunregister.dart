import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/otp_verification.dart';
import 'package:senior_citizen_app/services/api_service.dart';

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
  bool isLoading = false;

  Future<void> _registerVolunteer() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await ApiService.registerVolunteer(
        name: name,
        phone: phone,
        occupation: occupationController.text.trim(),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            phone: phone,
            flow: OtpFlow.volunteerRegister,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
              controller: ageController,
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
              controller: occupationController,
              decoration: const InputDecoration(labelText: "Occupation"),
            ),
            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: isLoading ? null : _registerVolunteer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
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
