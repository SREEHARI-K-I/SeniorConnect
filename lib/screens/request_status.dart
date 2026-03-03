import 'package:flutter/material.dart';
import 'package:senior_citizen_app/services/api_service.dart';

class RequestStatusListScreen extends StatefulWidget {
  const RequestStatusListScreen({super.key});

  @override
  State<RequestStatusListScreen> createState() =>
      _RequestStatusListScreenState();
}

class _RequestStatusListScreenState extends State<RequestStatusListScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getMyServiceRequests();
      if (!mounted) return;
      setState(() => requests = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  (Color, IconData) _statusLook(String status) {
    switch (status) {
      case 'accepted':
        return (Colors.green, Icons.check_circle);
      case 'completed':
        return (Colors.teal, Icons.done_all);
      case 'rejected':
        return (Colors.red, Icons.cancel);
      case 'cancelled':
        return (Colors.redAccent, Icons.remove_circle);
      default:
        return (Colors.orange, Icons.hourglass_top);
    }
  }

  String _prettyStatus(String status) {
    if (status.isEmpty) return 'PENDING';
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text('No requests yet'))
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final status = (request['status'] ?? 'open').toString();
                  final (statusColor, statusIcon) = _statusLook(status);
                  final createdAt = (request['created_at'] ?? '').toString();

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: Icon(statusIcon, size: 36, color: statusColor),
                      title: Text(
                        (request['category'] ?? '-').toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Requested on ${createdAt.isEmpty ? '-' : createdAt.split(' ').first}\n'
                          'Volunteer: ${(request['volunteer_name'] ?? 'Not assigned')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      trailing: Text(
                        _prettyStatus(status),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
