import 'package:flutter/material.dart';

class RequestStatusScreen extends StatelessWidget {
  const RequestStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TEMPORARY STATUS FLAG (to be replaced by backend response)
    // possible values: "pending", "accepted", "rejected"
    final String requestStatus = "accepted";

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String description;

    switch (requestStatus) {
      case "accepted":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = "Request Accepted";
        description =
            "Your request has been accepted.\nA volunteer will reach you shortly.";
        break;

      case "rejected":
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = "Request Rejected";
        description =
            "Your request was rejected.\nPlease contact Panchayat for details.";
        break;

      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        statusText = "Request Pending";
        description =
            "Your request is under review.\nPlease wait for approval.";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Status"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 90, color: statusColor),

                  const SizedBox(height: 20),

                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Back", style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
