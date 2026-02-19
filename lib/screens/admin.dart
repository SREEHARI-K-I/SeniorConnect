import 'package:flutter/material.dart';
import 'package:senior_citizen_app/screens/citizenrequest.dart';
import 'package:senior_citizen_app/screens/login.dart';
import 'package:senior_citizen_app/screens/volunrequest.dart';
import 'package:senior_citizen_app/screens/volunteerlist.dart';
import 'package:senior_citizen_app/screens/userlist.dart';
import 'package:senior_citizen_app/services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isLoadingStats = true;
  Map<String, dynamic> stats = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => isLoadingStats = true);
    try {
      final data = await ApiService.getAdminStats();
      if (!mounted) return;
      setState(() => stats = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: Column(
        children: [
          /// 🔵 TOP PROFILE / HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 36,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Admin",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "System Administrator",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: isLoadingStats
                ? const LinearProgressIndicator()
                : Row(
                    children: [
                      _statCard(
                        label: "Users",
                        value: "${stats["total_users"] ?? 0}",
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        label: "Pending",
                        value: "${stats["pending_requests"] ?? 0}",
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        label: "Volunteers",
                        value: "${stats["volunteers"] ?? 0}",
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 18),

          /// 📋 ACTION BUTTONS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _actionTile(
                    title: "Volunteer Requests",
                    icon: Icons.volunteer_activism,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VolunteerRequestsScreen(),
                        ),
                      );
                      _loadStats();
                    },
                  ),

                  _actionTile(
                    title: "Citizen Requests",
                    icon: Icons.person_add_alt,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CitizenRequestsScreen(),
                        ),
                      );
                      _loadStats();
                    },
                  ),

                  _actionTile(
                    title: "Citizens",
                    icon: Icons.people,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllUsersScreen(),
                        ),
                      );
                    },
                  ),

                  _actionTile(
                    title: "Volunteers",
                    icon: Icons.group,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllVolunteersScreen(),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  /// 🚪 LOGOUT BUTTON
                  ElevatedButton(
                    onPressed: () async {
                      await ApiService.clearSession();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: const Color.fromARGB(255, 229, 132, 53),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Logout", style: TextStyle(fontSize: 18)),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 REUSABLE ACTION TILE
  Widget _actionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
