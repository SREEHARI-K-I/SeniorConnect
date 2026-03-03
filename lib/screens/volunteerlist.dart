import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:senior_citizen_app/services/api_service.dart';

class AllVolunteersScreen extends StatefulWidget {
  const AllVolunteersScreen({super.key});

  @override
  State<AllVolunteersScreen> createState() => _AllVolunteersScreenState();
}

class _AllVolunteersScreenState extends State<AllVolunteersScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> volunteers = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadVolunteers();
  }

  Future<void> _loadVolunteers() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getAllVolunteers();
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

  String _statusLabel(Map<String, dynamic> volunteer) {
    final status = (volunteer['status'] ?? '').toString();
    final verified = volunteer['is_verified'] == 1;
    if (!verified) return 'Unverified';
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
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
        title: const Text('All Volunteers'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : volunteers.isEmpty
          ? const Center(child: Text('No volunteers found'))
          : RefreshIndicator(
              onRefresh: _loadVolunteers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: volunteers.length,
                itemBuilder: (context, index) {
                  final volunteer = volunteers[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Builder(
                        builder: (_) {
                          final bytes = _decodePhoto(
                            volunteer['profile_photo']?.toString(),
                          );
                          if (bytes == null) {
                            return const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.volunteer_activism,
                                color: Colors.white,
                              ),
                            );
                          }
                          return CircleAvatar(
                            backgroundImage: MemoryImage(bytes),
                          );
                        },
                      ),
                      title: Text(
                        (volunteer['name'] ?? '-').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Phone: ${volunteer['phone'] ?? '-'}\n'
                        'Ward: ${volunteer['ward'] ?? '-'} | '
                        'Panchayat: ${volunteer['panchayat'] ?? '-'}\n'
                        'Status: ${_statusLabel(volunteer)}',
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: () {
                          _showReportDialog(context, volunteer);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Details'),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showReportDialog(BuildContext context, Map<String, dynamic> volunteer) {
    final bytes = _decodePhoto(volunteer['profile_photo']?.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text((volunteer['name'] ?? 'Volunteer').toString()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 34,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                child: bytes == null
                    ? const Icon(Icons.person, size: 36, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Phone: ${volunteer['phone'] ?? '-'}\n'
              'Age: ${volunteer['age'] ?? '-'}\n'
              'Gender: ${volunteer['gender'] ?? '-'}\n'
              'Ward: ${volunteer['ward'] ?? '-'}\n'
              'Panchayat: ${volunteer['panchayat'] ?? '-'}\n'
              'Occupation: ${volunteer['occupation'] ?? '-'}\n'
              'Status: ${_statusLabel(volunteer)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
