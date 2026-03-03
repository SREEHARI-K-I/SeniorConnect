import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:senior_citizen_app/screens/service_request.dart';
import 'package:senior_citizen_app/screens/login.dart';
import 'package:senior_citizen_app/screens/volunhistory.dart';
import 'package:senior_citizen_app/services/api_service.dart';
import 'package:senior_citizen_app/services/push_notification_service.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  bool isAvailable = false;
  bool isLoading = true;
  String volunteerName = 'Volunteer';
  String volunteerPhone = '-';
  Uint8List? volunteerPhotoBytes;
  int rewardPoints = 0;
  Timer? _emergencyPollTimer;
  final Set<int> _seenSosIds = <int>{};

  Uint8List? _decodeProfilePhoto(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final value = raw.trim();
      if (value.startsWith('data:image')) {
        final parts = value.split(',');
        if (parts.length == 2) return base64Decode(parts[1]);
      }
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    PushNotificationService.syncVolunteerDeviceToken();
    _loadDashboard();
    _primeSeenSosIds();
    _emergencyPollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _pollForSosAlerts();
    });
  }

  @override
  void dispose() {
    _emergencyPollTimer?.cancel();
    _stopEmergencyBeep();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => isLoading = true);
    try {
      final name = await ApiService.getUserName();
      final phone = await ApiService.getUserPhone();
      final photo = await ApiService.getUserProfilePhoto();
      final decodedPhoto = _decodeProfilePhoto(photo);

      if (!mounted) return;
      setState(() {
        volunteerName = name ?? 'Volunteer';
        volunteerPhone = phone ?? '-';
        volunteerPhotoBytes = decodedPhoto;
      });
    } catch (_) {
      // Keep default identity values on transient failures.
    }

    try {
      final liveProfile = await ApiService.getResponderProfile();
      final livePhoto = _decodeProfilePhoto(liveProfile['profile_photo']?.toString());
      if (!mounted) return;
      setState(() {
        volunteerName =
            (liveProfile['name'] ?? volunteerName).toString().trim().isEmpty
            ? volunteerName
            : (liveProfile['name']).toString();
        volunteerPhone =
            (liveProfile['phone'] ?? volunteerPhone).toString().trim().isEmpty
            ? volunteerPhone
            : (liveProfile['phone']).toString();
        if (livePhoto != null) {
          volunteerPhotoBytes = livePhoto;
        }
      });
    } catch (_) {
      // Keep current values if profile fetch fails.
    }

    try {
      final available = await ApiService.getVolunteerAvailability();
      if (!mounted) return;
      setState(() => isAvailable = available);
    } catch (_) {
      // Keep previous availability on transient failures.
    }

    try {
      final history = await ApiService.getVolunteerHistory();
      if (!mounted) return;
      setState(
        () => rewardPoints =
            history.where((h) => h['status'] == 'completed').length * 10,
      );
    } catch (_) {
      // Keep previous reward count on transient failures.
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pollForSosAlerts() async {
    try {
      final data = await ApiService.getVolunteerRequests();
      final List<int> newSos = data
          .where(
            (row) =>
                (row['is_emergency'] == 1 || row['is_emergency'] == true) &&
                (row['emergency_type'] ?? '').toString().toLowerCase() ==
                    'sos' &&
                row['id'] is int &&
                !_seenSosIds.contains(row['id'] as int),
          )
          .map((row) => row['id'] as int)
          .toList();

      for (final row in data) {
        if ((row['is_emergency'] == 1 || row['is_emergency'] == true) &&
            row['id'] is int) {
          _seenSosIds.add(row['id'] as int);
        }
      }

      if (newSos.isNotEmpty) {
        await FlutterRingtonePlayer().play(
          android: AndroidSounds.alarm,
          ios: IosSounds.alarm,
          looping: false,
          volume: 1.0,
          asAlarm: true,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('New SOS alert received')));
      }
    } catch (_) {
      // Ignore transient polling failures.
    }
  }

  Future<void> _stopEmergencyBeep() async {
    await PushNotificationService.stopSosAlarm();
    await FlutterRingtonePlayer().stop();
  }

  Future<void> _primeSeenSosIds() async {
    try {
      final data = await ApiService.getVolunteerRequests();
      for (final row in data) {
        if ((row['is_emergency'] == 1 || row['is_emergency'] == true) &&
            row['id'] is int) {
          _seenSosIds.add(row['id'] as int);
        }
      }
    } catch (_) {
      // Ignore seed failures.
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
      await ApiService.updateVolunteerAvailability(
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Volunteer Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _stopEmergencyBeep();
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
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 20,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: volunteerPhotoBytes != null
                              ? MemoryImage(volunteerPhotoBytes!)
                              : null,
                          child: volunteerPhotoBytes == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.blue,
                                )
                              : null,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          volunteerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Phone: $volunteerPhone',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                    isAvailable
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: isAvailable
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isAvailable
                                        ? 'Available for Service'
                                        : 'Not Available',
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
                                onChanged: _toggleAvailability,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
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
                              children: [
                                const Text(
                                  'Reward Points',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '$rewardPoints',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: () {
                            _stopEmergencyBeep();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PendingRequestsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment),
                          label: const Text('View Pending Service Requests'),
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
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const VolunteerActivityHistory(),
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
                          child: const Text('View Activity History'),
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
