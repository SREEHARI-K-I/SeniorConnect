import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:senior_citizen_app/services/api_service.dart';

class EmergencyStatusScreen extends StatefulWidget {
  final String type; // "sos" or "ambulance"

  const EmergencyStatusScreen({super.key, required this.type});

  @override
  State<EmergencyStatusScreen> createState() => _EmergencyStatusScreenState();
}

class _EmergencyStatusScreenState extends State<EmergencyStatusScreen> {
  bool isLoading = true;
  String statusMessage = "Sending emergency alert...";
  String detailMessage = "";
  Color iconColor = Colors.red;
  IconData iconData = Icons.warning_rounded;

  @override
  void initState() {
    super.initState();
    _sendEmergency();
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location service is disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _sendEmergency() async {
    final isAmbulance = widget.type == "ambulance";

    setState(() {
      iconData = isAmbulance ? Icons.local_hospital : Icons.warning_rounded;
      iconColor = isAmbulance ? Colors.deepOrange : Colors.red;
    });

    try {
      final pos = await _getCurrentPosition();
      final response = await ApiService.sendEmergencyAlert(
        type: widget.type,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      final assigned = response["assigned_volunteer"];
      final volunteerLine = assigned is Map<String, dynamic>
          ? "Responder: ${assigned["name"] ?? "-"} (${assigned["distance_km"] ?? "-"} km away)"
          : "No active nearby responder. Alert is recorded for dispatch.";

      if (!mounted) return;
      setState(() {
        statusMessage = isAmbulance
            ? "Emergency Medical Request Sent"
            : "SOS Alert Activated";
        detailMessage = volunteerLine;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        statusMessage = "Emergency alert failed";
        detailMessage = e.toString().replaceFirst("Exception: ", "");
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAmbulance = widget.type == "ambulance";

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
              iconData,
              size: 100,
              color: iconColor,
            ),
            const SizedBox(height: 30),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: CircularProgressIndicator(),
              ),

            Text(
              statusMessage,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Text(
              isLoading
                  ? "Getting your current location and notifying nearest responder."
                  : detailMessage,
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
