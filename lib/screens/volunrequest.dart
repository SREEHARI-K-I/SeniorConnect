import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:senior_citizen_app/services/api_service.dart';

class VolunteerRequestsScreen extends StatefulWidget {
  const VolunteerRequestsScreen({super.key});

  @override
  State<VolunteerRequestsScreen> createState() =>
      _VolunteerRequestsScreenState();
}

class _VolunteerRequestsScreenState extends State<VolunteerRequestsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> volunteers = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getPendingVolunteers();
      if (!mounted) return;
      setState(() => volunteers = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _approveOrReject(int userId, bool approve) async {
    try {
      if (approve) {
        await ApiService.approveUser(userId);
      } else {
        await ApiService.rejectUser(userId);
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Uint8List? _decodePhoto(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final value = raw.trim();
      if (value.startsWith('data:image')) {
        final parts = value.split(',');
        if (parts.length == 2) {
          return base64Decode(parts[1]);
        }
      }
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Requests'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : volunteers.isEmpty
          ? const Center(child: Text('No pending volunteer requests'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: volunteers.length,
                itemBuilder: (context, index) {
                  final volunteer = volunteers[index];
                  final int userId = volunteer['id'] as int;
                  final photoBytes = _decodePhoto(
                    volunteer['profile_photo']?.toString(),
                  );
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: photoBytes != null
                                  ? MemoryImage(photoBytes)
                                  : null,
                              child: photoBytes == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 34,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Name: ${volunteer['name'] ?? '-'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Phone: ${volunteer['phone'] ?? '-'}'),
                          Text('Age: ${volunteer['age'] ?? '-'}'),
                          Text('Ward: ${volunteer['ward'] ?? '-'}'),
                          Text('Panchayat: ${volunteer['panchayat'] ?? '-'}'),
                          Text('Occupation: ${volunteer['occupation'] ?? '-'}'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Accept only after physical verification at the Panchayat office.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _approveOrReject(userId, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Accept'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _approveOrReject(userId, false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Reject'),
                                ),
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
