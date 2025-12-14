import 'package:flutter/material.dart';

class VolunteerActivityHistory extends StatelessWidget {
  const VolunteerActivityHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Activity History"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          activityCard(
            title: "Grocery Assistance",
            date: "12 Aug 2025",
            location: "Kochi",
            icon: Icons.shopping_cart,
          ),
          activityCard(
            title: "Hospital Visit Help",
            date: "05 Aug 2025",
            location: "Ernakulam",
            icon: Icons.local_hospital,
          ),
          activityCard(
            title: "Medicine Pickup",
            date: "29 Jul 2025",
            location: "Aluva",
            icon: Icons.local_pharmacy,
          ),
          activityCard(
            title: "Home Cleaning Support",
            date: "18 Jul 2025",
            location: "Thrissur",
            icon: Icons.cleaning_services,
          ),
        ],
      ),
    );
  }

  /// SIMPLE CARD FUNCTION (not reusable widget class)
  Widget activityCard({
    required String title,
    required String date,
    required String location,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blue.shade100,
              child: Icon(icon, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("📅 $date"),
                  Text("📍 $location"),
                ],
              ),
            ),
            const Text(
              "Completed",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
