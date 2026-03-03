import 'package:flutter/material.dart';
import 'package:senior_citizen_app/services/api_service.dart';

class VolunteerActivityHistory extends StatefulWidget {
  const VolunteerActivityHistory({super.key});

  @override
  State<VolunteerActivityHistory> createState() =>
      _VolunteerActivityHistoryState();
}

class _VolunteerActivityHistoryState extends State<VolunteerActivityHistory> {
  bool isLoading = true;
  List<Map<String, dynamic>> history = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getVolunteerHistory();
      if (!mounted) return;
      setState(() => history = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Activity History'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(child: Text('No completed/rejected activities yet'))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final status = (item['status'] ?? '').toString();
                  return _activityCard(
                    title: (item['category'] ?? '-').toString(),
                    date: (item['completed_at'] ?? item['created_at'] ?? '-')
                        .toString()
                        .split(' ')
                        .first,
                    location:
                        'Ward ${item['ward'] ?? '-'}, ${item['panchayat'] ?? '-'}',
                    status: status,
                  );
                },
              ),
            ),
    );
  }

  Widget _activityCard({
    required String title,
    required String date,
    required String location,
    required String status,
  }) {
    final isCompleted = status == 'completed';

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
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.cancel,
                color: isCompleted ? Colors.green : Colors.red,
                size: 28,
              ),
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
                  Text('Date: $date'),
                  Text('Location: $location'),
                ],
              ),
            ),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: isCompleted ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
