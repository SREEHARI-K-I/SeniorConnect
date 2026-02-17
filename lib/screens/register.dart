import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/login.dart';
import 'package:senior_citizen_app/screens/otp_verification.dart';
import 'package:senior_citizen_app/screens/aadhar_scanner_screen.dart';
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
  final pinController = TextEditingController();
  final housenameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    panchayatController.dispose();
    wardController.dispose();
    houseController.dispose();
    healthController.dispose();
    pinController.dispose();
    housenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 🔥 SCAN AADHAR BUTTON
            /// 🔵 SCAN FRONT SIDE
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AadharScannerScreen(
                      isFront: true,
                      onDataExtracted: (data) {
                        if (data.name != null &&
                            data.name!.isNotEmpty &&
                            data.name!.toLowerCase() != "unidentified") {
                          nameController.text = data.name!;
                        }

                        if (data.age != null && data.age! > 0) {
                          ageController.text = data.age!.toString();
                        }
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.credit_card),
              label: const Text("Scan Aadhar Front Side"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 15),

            /// 🟢 SCAN BACK SIDE
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AadharScannerScreen(
                      isFront: false,
                      onDataExtracted: (data) {
                        if (data.houseName != null &&
                            data.houseName!.isNotEmpty) {
                          housenameController.text = data.houseName!;
                        }

                        if (data.pincode != null && data.pincode!.isNotEmpty) {
                          pinController.text = data.pincode!;
                        }
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.home),
              label: const Text("Scan Aadhar Back Side"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 25),

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

            /// PHONE
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),

            /// HOUSE NAME (From Back Side)
            TextField(
              controller: housenameController,
              decoration: const InputDecoration(labelText: "House Name"),
            ),
            const SizedBox(height: 15),

            /// HOUSE NUMBER
            TextField(
              controller: houseController,
              decoration: const InputDecoration(labelText: "House Number"),
            ),
            const SizedBox(height: 15),

            /// WARD
            TextField(
              controller: wardController,
              decoration: const InputDecoration(labelText: "Ward Number"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            /// PANCHAYAT
            TextField(
              controller: panchayatController,
              decoration: const InputDecoration(labelText: "Panchayat"),
            ),
            const SizedBox(height: 15),

            /// PINCODE (From Back Side)
            TextField(
              controller: pinController,
              decoration: const InputDecoration(labelText: "Pincode"),
              keyboardType: TextInputType.number,
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
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
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
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Register"),
            ),

            const SizedBox(height: 20),

            /// VOLUNTEER BUTTON
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VolunteerRegisterScreen(),
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

            /// LOGIN BUTTON
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
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
