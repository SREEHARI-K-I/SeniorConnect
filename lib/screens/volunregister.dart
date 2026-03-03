import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  File? _selectedPhotoFile;
  String? _profilePhotoData;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    wardController.dispose();
    panchayatController.dispose();
    occupationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 720,
    );
    if (image == null) return;

    final file = File(image.path);
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);

    if (!mounted) return;
    setState(() {
      _selectedPhotoFile = file;
      _profilePhotoData = "data:image/jpeg;base64,$encoded";
    });
  }

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
        profilePhoto: _profilePhotoData,
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
            GestureDetector(
              onTap: isLoading ? null : _pickPhoto,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: _selectedPhotoFile != null
                    ? FileImage(_selectedPhotoFile!)
                    : null,
                child: _selectedPhotoFile == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 30,
                        color: Colors.blue,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isLoading ? null : _pickPhoto,
              child: const Text("Add Volunteer Photo"),
            ),
            const SizedBox(height: 10),
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
