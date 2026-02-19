import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/login.dart';
import 'package:senior_citizen_app/screens/request_status.dart';
import 'package:senior_citizen_app/screens/volunavail.dart';
import 'package:senior_citizen_app/screens/emergency_status.dart';
import 'package:senior_citizen_app/services/api_service.dart';

class CitizenDashboard extends StatelessWidget {
  const CitizenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Citizen Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.clearSession();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------------- EMERGENCY SECTION ----------------
            const Text(
              "Emergency Assistance",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _emergencyCard(
                  context,
                  title: "SOS",
                  icon: Icons.warning_rounded,
                  color: Colors.red,
                  type: "sos",
                ),
                const SizedBox(width: 16),
                _emergencyCard(
                  context,
                  title: "Ambulance",
                  icon: Icons.local_hospital,
                  color: Colors.deepOrange,
                  type: "ambulance",
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// ---------------- SERVICES ----------------
            const Text(
              "Select Service Category",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _serviceCard(
                    context,
                    icon: Icons.local_hospital,
                    label: "Medical",
                  ),
                  _serviceCard(
                    context,
                    icon: Icons.construction,
                    label: "Infrastructure",
                  ),
                  _serviceCard(context, icon: Icons.people, label: "Social"),
                  _serviceCard(
                    context,
                    icon: Icons.cleaning_services,
                    label: "Cleaning",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// ---------------- STATUS BUTTON ----------------
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RequestStatusListScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Track Request Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- SERVICE CARD ----------------
  Widget _serviceCard(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AvailableVolunteersScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- EMERGENCY CARD ----------------
  Widget _emergencyCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmergencyStatusScreen(type: type),
            ),
          );
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
