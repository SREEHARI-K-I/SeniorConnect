import 'package:flutter/material.dart';
import 'package:senior_citizen_app/services/api_service.dart';

class CitizenRequestsScreen extends StatefulWidget {
  const CitizenRequestsScreen({super.key});

  @override
  State<CitizenRequestsScreen> createState() => _CitizenRequestsScreenState();
}

class _CitizenRequestsScreenState extends State<CitizenRequestsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> seniors = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getPendingSeniors();
      if (!mounted) return;
      setState(() => seniors = data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Requests'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : seniors.isEmpty
          ? const Center(child: Text('No pending citizen requests'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: seniors.length,
                itemBuilder: (context, index) {
                  final senior = seniors[index];
                  final int userId = senior['id'] as int;
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
                          Text(
                            'Citizen Name: ${senior['name'] ?? '-'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Phone: ${senior['phone'] ?? '-'}'),
                          Text('Age: ${senior['age'] ?? '-'}'),
                          Text('Gender: ${senior['gender'] ?? '-'}'),
                          Text('Ward: ${senior['ward'] ?? '-'}'),
                          Text('Panchayat: ${senior['panchayat'] ?? '-'}'),
                          Text('House Number: ${senior['house_number'] ?? '-'}'),
                          Text('House: ${senior['house_name'] ?? '-'}'),
                          Text('Pincode: ${senior['pincode'] ?? '-'}'),
                          Text(
                            'Health Issues: ${senior['health_issues'] ?? '-'}',
                          ),
                          Text('Occupation: ${senior['occupation'] ?? '-'}'),
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
