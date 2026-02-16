import 'package:flutter/material.dart';

class EmergencyStatusScreen extends StatelessWidget {
  final String type; // "sos" or "ambulance"

  const EmergencyStatusScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isAmbulance = type == "ambulance";

    return Scaffold(
      appBar: AppBar(
        title: Text(isAmbulance ? "Ambulance Assistance" : "SOS Alert"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAmbulance ? Icons.local_hospital : Icons.warning_rounded,
              size: 100,
              color: isAmbulance ? Colors.deepOrange : Colors.red,
            ),
            const SizedBox(height: 30),

            Text(
              isAmbulance
                  ? "Emergency Medical Request Sent"
                  : "SOS Alert Activated",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Text(
              isAmbulance
                  ? "Nearby medical services and volunteers are being notified. Your location has been shared for quick response."
                  : "Nearby volunteers and administrators are notified immediately. Please stay calm.",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Back to Dashboard",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
