import 'package:flutter/material.dart';

class AllVolunteersScreen extends StatelessWidget {
  const AllVolunteersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Volunteers"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4, // dummy volunteers
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.volunteer_activism, color: Colors.white),
              ),
              title: const Text(
                "Arun Kumar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Phone: 9876543210\nServices Done: 12"),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () {
                  _showReportDialog(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("Report"),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Volunteer Report"),
        content: const Text(
          "Total Services Completed: 12\n"
          "Medical Assistance: 5\n"
          "Grocery Help: 4\n"
          "Emergency Support: 3",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
