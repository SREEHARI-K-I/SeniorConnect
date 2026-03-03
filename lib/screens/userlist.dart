import 'package:flutter/material.dart';
import 'package:senior_citizen_app/services/api_service.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> users = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getAllUsers();
      if (!mounted) return;
      setState(() => users = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _statusLabel(Map<String, dynamic> user) {
    final status = (user['status'] ?? '').toString();
    final verified = user['is_verified'] == 1;
    if (!verified) return 'Unverified';
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Users"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text('No users found'))
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        (user['name'] ?? '-').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Phone: ${user['phone'] ?? '-'}\n'
                        'Ward: ${user['ward'] ?? '-'} | Panchayat: ${user['panchayat'] ?? '-'}\n'
                        'Status: ${_statusLabel(user)}',
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: () => _showDetailsDialog(context, user),
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

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text((user['name'] ?? 'User').toString()),
        content: Text(
          'Phone: ${user['phone'] ?? '-'}\n'
          'Age: ${user['age'] ?? '-'}\n'
          'Gender: ${user['gender'] ?? '-'}\n'
          'Ward: ${user['ward'] ?? '-'}\n'
          'Panchayat: ${user['panchayat'] ?? '-'}\n'
          'House Number: ${user['house_number'] ?? '-'}\n'
          'House: ${user['house_name'] ?? '-'}\n'
          'Pincode: ${user['pincode'] ?? '-'}\n'
          'Health Issues: ${user['health_issues'] ?? '-'}\n'
          'Occupation: ${user['occupation'] ?? '-'}\n'
          'Status: ${_statusLabel(user)}',
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
