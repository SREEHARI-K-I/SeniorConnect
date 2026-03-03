import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/login.dart';
import 'package:senior_citizen_app/screens/otp_verification.dart';
import 'package:senior_citizen_app/screens/aadhar_scanner_screen.dart';
import 'package:senior_citizen_app/screens/volunregister.dart';
import 'package:senior_citizen_app/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final genderController = TextEditingController();
  final phoneController = TextEditingController();
  final panchayatController = TextEditingController();
  final wardController = TextEditingController();
  final houseController = TextEditingController();
  final healthController = TextEditingController();
  final occupationController = TextEditingController();
  final pinController = TextEditingController();
  final housenameController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    panchayatController.dispose();
    wardController.dispose();
    houseController.dispose();
    healthController.dispose();
    occupationController.dispose();
    pinController.dispose();
    housenameController.dispose();
    super.dispose();
  }

  Future<void> _registerSenior() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final age = ageController.text.trim();
    final gender = genderController.text.trim();
    final ward = wardController.text.trim();
    final panchayat = panchayatController.text.trim();
    final houseNumber = houseController.text.trim();
    final houseName = housenameController.text.trim();
    final pincode = pinController.text.trim();

    if (name.isEmpty || phone.isEmpty) return;
    if (age.isEmpty ||
        gender.isEmpty ||
        ward.isEmpty ||
        panchayat.isEmpty ||
        houseNumber.isEmpty ||
        houseName.isEmpty ||
        pincode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Fill age, gender, ward, panchayat, house number, house name and pincode",
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await ApiService.registerSenior(
        name: name,
        phone: phone,
        age: age,
        gender: gender,
        ward: ward,
        panchayat: panchayat,
        houseNumber: houseNumber,
        houseName: houseName,
        pincode: pincode,
        healthIssues: healthController.text.trim(),
        occupation: occupationController.text.trim(),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OTPVerificationScreen(phone: phone, flow: OtpFlow.seniorRegister),
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
                        if (data.name.isNotEmpty &&
                            data.name.toLowerCase() != "unidentified") {
                          nameController.text = data.name;
                        }

                        if (data.age > 0) {
                          ageController.text = data.age.toString();
                        }

                        /// 🔥 ADD THIS FOR GENDER
                        if (data.gender.isNotEmpty) {
                          genderController.text = data.gender;
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
                        if (data.houseName.isNotEmpty) {
                          housenameController.text = data.houseName;
                        }

                        if (data.pincode.isNotEmpty) {
                          pinController.text = data.pincode;
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

            TextField(
              controller: genderController,
              decoration: const InputDecoration(labelText: "Gender"),
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

            const SizedBox(height: 15),

            TextField(
              controller: occupationController,
              decoration: const InputDecoration(labelText: "Occupation"),
            ),

            const SizedBox(height: 30),

            /// REGISTER BUTTON
            ElevatedButton(
              onPressed: isLoading ? null : _registerSenior,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
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
                  : const Text("Register"),
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
