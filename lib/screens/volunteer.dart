import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/service_request.dart';
import 'package:senior_citizen_app/screens/login.dart';
import 'package:senior_citizen_app/screens/volunhistory.dart';
import 'package:senior_citizen_app/services/api_service.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  bool isAvailable = false; // availability status

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Volunteer Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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

      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔵 PROFILE + AVAILABILITY SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.blue),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Arun Kumar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Age: 28 | Phone: 9876543210",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  /// ✅ AVAILABILITY TOGGLE
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAvailable ? Icons.check_circle : Icons.cancel,
                              color: isAvailable
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isAvailable
                                  ? "Available for Service"
                                  : "Not Available",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        Switch(
                          value: isAvailable,
                          activeThumbColor: Colors.greenAccent,
                          onChanged: (value) {
                            setState(() {
                              isAvailable = value;
                            });

                            /// TODO (Backend):
                            /// Send availability status to API
                            /// volunteer_id + isAvailable
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🔹 MAIN CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  /// REWARD POINTS
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 25,
                        horizontal: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "Reward Points",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "120",
                                style: TextStyle(
                                  fontSize: 26,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.star, color: Colors.amber, size: 28),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// VIEW REQUESTS
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PendingRequestsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text("View Pending Service Requests"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// HISTORY
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VolunteerActivityHistory(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 55),
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text("View Activity History"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
