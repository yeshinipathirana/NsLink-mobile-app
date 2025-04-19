import 'package:flutter/material.dart';

class AddLectureMeetings extends StatelessWidget {
  const AddLectureMeetings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Add Meetings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: MeetingCard(isFirstItem: index == 0),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Add', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class MeetingCard extends StatelessWidget {
  final bool isFirstItem;

  const MeetingCard({super.key, this.isFirstItem = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'type of meeting',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                Icon(
                  Icons.cancel,
                  color: Colors.black45,
                  size: isFirstItem ? 24 : 20,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Thu, Feb 6',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              '10:00 AM-12:30 PM',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26C485),
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('View', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
