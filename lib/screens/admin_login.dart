import "package:flutter/material.dart";
import "package:senior_citizen_app/screens/otp_verification.dart";
import "package:senior_citizen_app/services/api_service.dart";

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendAdminOtp() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    if (phone.isEmpty || password.isEmpty) return;

    setState(() => isLoading = true);
    try {
      await ApiService.sendAdminLoginOtp(phone: phone, password: password);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OTPVerificationScreen(phone: phone, flow: OtpFlow.adminLogin),
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
        title: const Text("Admin Login"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _sendAdminOtp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
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
                  : const Text("Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
