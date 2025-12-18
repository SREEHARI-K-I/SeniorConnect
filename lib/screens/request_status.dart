import 'package:flutter/material.dart';

class RequestStatusListScreen extends StatelessWidget {
  const RequestStatusListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TEMPORARY DUMMY DATA (to be replaced by backend)
    final List<Map<String, String>> requests = [
      {
        "service": "Medical Assistance",
        "status": "accepted",
        "date": "10 Dec 2025",
      },
      {
        "service": "Infrastructure Repair",
        "status": "pending",
        "date": "12 Dec 2025",
      },
      {
        "service": "Social Support",
        "status": "rejected",
        "date": "13 Dec 2025",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Requests"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];

          Color statusColor;
          IconData statusIcon;

          switch (request["status"]) {
            case "accepted":
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              break;
            case "rejected":
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              break;
            default:
              statusColor = Colors.orange;
              statusIcon = Icons.hourglass_top;
          }

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Icon(statusIcon, size: 36, color: statusColor),
              title: Text(
                request["service"]!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Requested on ${request["date"]}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              trailing: Text(
                request["status"]!.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
