import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/admin.dart';
import 'package:senior_citizen_app/screens/pending.dart';
import 'package:senior_citizen_app/screens/user.dart';
import 'package:senior_citizen_app/screens/volunteer.dart';
import 'package:senior_citizen_app/services/api_service.dart';

enum OtpFlow { seniorRegister, volunteerRegister, userLogin, adminLogin }

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  final OtpFlow flow;

  const OTPVerificationScreen({
    super.key,
    required this.phone,
    required this.flow,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;

  bool get _isLoginFlow =>
      widget.flow == OtpFlow.userLogin || widget.flow == OtpFlow.adminLogin;

  Future<void> _verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.isEmpty) return;

    setState(() => isLoading = true);

    try {
      if (widget.flow == OtpFlow.seniorRegister ||
          widget.flow == OtpFlow.volunteerRegister) {
        await ApiService.verifyRegisterOtp(phone: widget.phone, otp: otp);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ApprovalPendingScreen()),
          (_) => false,
        );
        return;
      }

      final response = widget.flow == OtpFlow.adminLogin
          ? await ApiService.verifyAdminLoginOtp(phone: widget.phone, otp: otp)
          : await ApiService.verifyUserLoginOtp(phone: widget.phone, otp: otp);

      final token = (response["token"] ?? "").toString();
      final role = (response["role"] ?? "").toString();
      final name = (response["name"] ?? "").toString();
      final status = response["status"]?.toString();

      await ApiService.saveSession(
        token: token,
        role: role,
        name: name,
        phone: widget.phone,
        status: status,
      );

      if (!mounted) return;
      if (role == "admin") {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
          (_) => false,
        );
      } else if (role == "volunteer") {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VolunteerDashboard()),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CitizenDashboard()),
          (_) => false,
        );
      }
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
        title: Text(_isLoginFlow ? "Login OTP" : "Verify OTP"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
              onPressed: isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
