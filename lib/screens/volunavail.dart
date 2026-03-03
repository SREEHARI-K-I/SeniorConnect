import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:senior_citizen_app/services/api_service.dart';

class AvailableVolunteersScreen extends StatefulWidget {
  final String category;

  const AvailableVolunteersScreen({super.key, required this.category});

  @override
  State<AvailableVolunteersScreen> createState() =>
      _AvailableVolunteersScreenState();
}

class _AvailableVolunteersScreenState extends State<AvailableVolunteersScreen> {
  int? selectedVolunteerIndex;
  bool isLoading = true;
  bool isSubmitting = false;
  List<Map<String, dynamic>> volunteers = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadVolunteers();
  }

  Future<void> _loadVolunteers() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getAvailableVolunteers();
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

  Future<void> _submitRequest() async {
    if (isSubmitting) return;
    if (selectedVolunteerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a volunteer first')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final selectedVolunteer = selectedVolunteerIndex != null
          ? volunteers[selectedVolunteerIndex!]
          : null;
      final preferredVolunteerId = selectedVolunteer?['id'] as int?;

      await ApiService.createServiceRequest(
        category: widget.category,
        preferredVolunteerId: preferredVolunteerId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service request sent successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
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

  String _valueOrFallback(dynamic value, String fallback) {
    final text = (value ?? "").toString().trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Volunteers'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : volunteers.isEmpty
          ? const Center(child: Text('No volunteers available now'))
          : RefreshIndicator(
              onRefresh: _loadVolunteers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: volunteers.length,
                itemBuilder: (context, index) {
                  final volunteer = volunteers[index];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          selectedVolunteerIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Builder(
                              builder: (_) {
                                final bytes = _decodePhoto(
                                  volunteer['profile_photo']?.toString(),
                                );
                                if (bytes != null) {
                                  return CircleAvatar(
                                    radius: 34,
                                    backgroundImage: MemoryImage(bytes),
                                  );
                                }
                                return const CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Colors.blue,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (volunteer['name'] ?? '-').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Phone: ${_valueOrFallback(volunteer['phone'], 'Not provided')}\n'
                                    'Ward: ${_valueOrFallback(volunteer['ward'], 'Not set')} | '
                                    'Panchayat: ${_valueOrFallback(volunteer['panchayat'], 'Not set')}\n'
                                    'Occupation: ${_valueOrFallback(volunteer['occupation'], 'Not set')}',
                                  ),
                                ],
                              ),
                            ),
                            Radio<int>(
                              value: index,
                              groupValue: selectedVolunteerIndex,
                              onChanged: (value) {
                                setState(() {
                                  selectedVolunteerIndex = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Request Service',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
