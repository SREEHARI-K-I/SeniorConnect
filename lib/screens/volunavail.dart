import 'package:flutter/material.dart';

class AvailableVolunteersScreen extends StatefulWidget {
  const AvailableVolunteersScreen({super.key});

  @override
  State<AvailableVolunteersScreen> createState() =>
      _AvailableVolunteersScreenState();
}

class _AvailableVolunteersScreenState extends State<AvailableVolunteersScreen> {
  int? selectedVolunteerIndex;

  // Dummy data for now
  final List<Map<String, String>> volunteers = [
    {"name": "Ramesh Kumar", "area": "Ward 3"},
    {"name": "Suresh Babu", "area": "Ward 1"},
    {"name": "Anil Raj", "area": "Ward 5"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Volunteers"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),

      body: ListView.builder(
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
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),

              title: Text(
                volunteer["name"]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              subtitle: Text("Area: ${volunteer["area"]}"),

              trailing: Radio<int>(
                value: index,
                groupValue: selectedVolunteerIndex,
                onChanged: (value) {
                  setState(() {
                    selectedVolunteerIndex = value;
                  });
                },
              ),

              onTap: () {
                setState(() {
                  selectedVolunteerIndex = index;
                });
              },
            ),
          );
        },
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            // Later → Submit service request
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Service request sent")),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Request Service",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
