import 'package:flutter/material.dart';

class ManageSchoolView extends StatefulWidget {
  const ManageSchoolView({super.key});

  @override
  State<ManageSchoolView> createState() => _ManageSchoolViewState();
}

class _ManageSchoolViewState extends State<ManageSchoolView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(137, 106, 101, 101),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
          child: SchoolDetailCard(),
        ),
      ),
    );
  }
}

class SchoolDetailCard extends StatelessWidget {
  SchoolDetailCard({super.key});

  final Map<String, String> schoolData = {
    'School Name': 'Anula Devi Balika Vidyalaya',
    'School Address': 'Anula Devi Balika Vidyalaya, Magalle, Galle',
    'School PhoneNumber': '0912256932',
    'School Type': 'Government',
    'School Educational Zone': 'Akmeemana',
    'Number of Students in School': '5000',
    'Number of Teachers in School': '500',
    'Number of NonAcadamic Staff': '150',
    'Infrastructure Components': '5000',
  };

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '• ',
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14.0),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'View School Details',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const Divider(thickness: 1, height: 15),
            ...schoolData.entries.map((entry) {
              return _buildDetailRow(entry.key, entry.value);
            }),
          ],
        ),
      ),
    );
  }
}
