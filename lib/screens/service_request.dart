import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:senior_citizen_app/services/api_service.dart';
import 'package:senior_citizen_app/services/push_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingRequestsScreen extends StatefulWidget {
  final bool ambulanceMode;
  const PendingRequestsScreen({super.key, this.ambulanceMode = false});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];
  Timer? _pollTimer;
  final Set<int> _seenEmergencyIds = <int>{};
  bool _hasLoadedOnce = false;
  final Map<int, TextEditingController> _completionOtpControllers =
      <int, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _hardStopEmergencyBeep();
    _loadRequests();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _loadRequests(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _stopEmergencyBeep();
    for (final controller in _completionOtpControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _otpControllerFor(int requestId) {
    return _completionOtpControllers.putIfAbsent(
      requestId,
      () => TextEditingController(),
    );
  }

  Future<void> _loadRequests({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    try {
      final data = widget.ambulanceMode
          ? await ApiService.getAmbulanceRequests()
          : await ApiService.getVolunteerRequests();
      final List<int> newSosIds = data
          .where(
            (row) =>
                (row['is_emergency'] == 1 || row['is_emergency'] == true) &&
                (row['emergency_type'] ?? '').toString().toLowerCase() ==
                    (widget.ambulanceMode ? 'ambulance' : 'sos') &&
                row['id'] is int &&
                !_seenEmergencyIds.contains(row['id'] as int),
          )
          .map((row) => row['id'] as int)
          .toList();

      for (final row in data) {
        if ((row['is_emergency'] == 1 || row['is_emergency'] == true) &&
            row['id'] is int) {
          _seenEmergencyIds.add(row['id'] as int);
        }
      }

      if (!mounted) return;
      setState(() => requests = data);

      if (_hasLoadedOnce && newSosIds.isNotEmpty) {
        await _playEmergencyBeep();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ambulanceMode
                  ? 'New ambulance alert received'
                  : 'New SOS alert received',
            ),
          ),
        );
      }
      _hasLoadedOnce = true;
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => isLoading = false);
    }
  }

  Future<void> _playEmergencyBeep() async {
    await FlutterRingtonePlayer().play(
      android: AndroidSounds.alarm,
      ios: IosSounds.alarm,
      looping: false,
      volume: 1.0,
      asAlarm: true,
    );
  }

  Future<void> _stopEmergencyBeep() async {
    await PushNotificationService.stopSosAlarm();
    await FlutterRingtonePlayer().stop();
  }

  Future<void> _hardStopEmergencyBeep() async {
    await _stopEmergencyBeep();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await _stopEmergencyBeep();
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  Future<void> _callSenior(String phone) async {
    final normalized = phone.replaceAll(RegExp(r"\s+"), "");
    if (normalized.isEmpty || normalized == "-") return;
    final uri = Uri.parse("tel:$normalized");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open phone dialer")),
      );
    }
  }

  Future<void> _onAction(int requestId, String action) async {
    try {
      await _hardStopEmergencyBeep();
      if (action == 'accept') {
        if (widget.ambulanceMode) {
          await ApiService.acceptAmbulanceRequest(requestId);
        } else {
          await ApiService.acceptVolunteerRequest(requestId);
        }
      } else if (action == 'reject') {
        if (widget.ambulanceMode) {
          await ApiService.rejectAmbulanceRequest(requestId);
        } else {
          await ApiService.rejectVolunteerRequest(requestId);
        }
      } else {
        if (widget.ambulanceMode) {
          await ApiService.completeAmbulanceRequest(requestId);
        } else {
          final otp = _otpControllerFor(requestId).text.trim();
          if (otp.length != 6) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enter 6-digit completion OTP')),
            );
            return;
          }
          await ApiService.completeVolunteerRequest(
            requestId,
            completionOtp: otp,
          );
          _otpControllerFor(requestId).clear();
        }
      }
      await _hardStopEmergencyBeep();
      await _loadRequests();
      await _hardStopEmergencyBeep();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _generateCompletionOtp(int requestId) async {
    try {
      final response = await ApiService.generateVolunteerCompletionOtp(requestId);
      if (!mounted) return;
      final otp = (response['otp'] ?? '').toString();
      final message = (response['message'] ?? 'Completion OTP generated')
          .toString();
      final text = otp.isNotEmpty ? '$message: $otp' : message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ambulanceMode ? 'Ambulance Alerts' : 'Pending Requests',
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? Center(
              child: Text(
                widget.ambulanceMode
                    ? 'No active ambulance alerts'
                    : 'No service requests available',
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final requestId = request['id'] as int;
                  final status = (request['status'] ?? 'open').toString();
                  final isAccepted = status == 'accepted';
                  final isEmergency =
                      request['is_emergency'] == 1 ||
                      request['is_emergency'] == true;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service: ${request['category'] ?? '-'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isEmergency)
                            Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                widget.ambulanceMode
                                    ? 'Ambulance Emergency'
                                    : 'Emergency Alert',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'Citizen: ${request['senior_name'] ?? '-'} '
                            '(Age ${request['senior_age'] ?? '-'})',
                          ),
                          Text(
                            'Ward: ${request['ward'] ?? '-'} | House: ${request['house_name'] ?? '-'}',
                          ),
                          if ((request['description'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text('Note: ${request['description']}'),
                          if (request['location_lat'] != null &&
                              request['location_lng'] != null)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Location: ${request['location_lat']}, ${request['location_lng']}',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final lat = double.tryParse(
                                      request['location_lat'].toString(),
                                    );
                                    final lng = double.tryParse(
                                      request['location_lng'].toString(),
                                    );
                                    if (lat == null || lng == null) return;
                                    _openInGoogleMaps(lat, lng);
                                  },
                                  child: const Text('Open in Maps'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 15),
                          if (!isAccepted)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _onAction(requestId, 'accept'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _onAction(requestId, 'reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                              ],
                            )
                          else if (widget.ambulanceMode)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _callSenior(
                                      (request['senior_phone'] ?? "")
                                          .toString(),
                                    ),
                                    icon: const Icon(Icons.call),
                                    label: const Text("Call Senior"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _onAction(requestId, 'complete'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                    ),
                                    child: const Text('Mark Completed'),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                TextField(
                                  controller: _otpControllerFor(requestId),
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: const InputDecoration(
                                    labelText: 'Senior Completion OTP',
                                    hintText: 'Enter 6-digit OTP',
                                    counterText: '',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _generateCompletionOtp(requestId),
                                        child: const Text('Generate OTP'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _onAction(requestId, 'complete'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                        ),
                                        child: const Text('Mark Completed'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
