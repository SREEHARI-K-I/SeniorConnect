import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:senior_citizen_app/screens/login.dart';
import 'package:senior_citizen_app/screens/service_request.dart';
import 'package:senior_citizen_app/services/api_service.dart';
import 'package:senior_citizen_app/services/push_notification_service.dart';

class AmbulanceDashboard extends StatefulWidget {
  const AmbulanceDashboard({super.key});

  @override
  State<AmbulanceDashboard> createState() => _AmbulanceDashboardState();
}

class _AmbulanceDashboardState extends State<AmbulanceDashboard> {
  bool isLoading = true;
  bool isAvailable = false;
  String name = "Ambulance";
  String phone = "-";

  @override
  void initState() {
    super.initState();
    PushNotificationService.syncVolunteerDeviceToken();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final loadedName = await ApiService.getUserName();
      final loadedPhone = await ApiService.getUserPhone();
      final available = await ApiService.getAmbulanceAvailability();

      if (!mounted) return;
      setState(() {
        name = loadedName ?? "Ambulance";
        phone = loadedPhone ?? "-";
        isAvailable = available;
      });
    } catch (_) {
      // Keep defaults.
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    final previous = isAvailable;
    setState(() => isAvailable = value);
    try {
      double? lat;
      double? lng;
      if (value) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = position.latitude;
        lng = position.longitude;
      }
      await ApiService.updateAmbulanceAvailability(
        value,
        latitude: lat,
        longitude: lng,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isAvailable = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ambulance Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await PushNotificationService.removeVolunteerDeviceToken();
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Phone: $phone", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text("Available for Ambulance Alerts"),
                    subtitle: Text(
                      isAvailable
                          ? "Active and location is shared"
                          : "Turn on to receive nearest alerts",
                    ),
                    value: isAvailable,
                    onChanged: _toggleAvailability,
                    activeColor: Colors.red,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PendingRequestsScreen(
                              ambulanceMode: true,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.notifications_active),
                      label: const Text("View Ambulance Alerts"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
