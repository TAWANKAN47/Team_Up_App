// lib/widgets/room_details_dialog.dart
import 'package:flutter/material.dart';

class RoomDetailsDialog extends StatelessWidget {
  final String roomName;
  final List<Map<String, dynamic>> participants;

  const RoomDetailsDialog({
    Key? key,
    required this.roomName,
    required this.participants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'รายละเอียดห้อง: $roomName',
        style: const TextStyle(color: Colors.orange),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: participants.isEmpty
            ? const Text('ไม่มีผู้เข้าร่วมในห้องนี้')
            : ListView.builder(
          shrinkWrap: true,
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return ListTile(
              leading: const Icon(Icons.person, color: Colors.orange),
              title: Text(participant['name'] ?? 'Unknown'),
              subtitle: Text('อายุ: ${participant['age']?.toString() ?? 'ไม่ระบุ'}'),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'ปิด',
            style: TextStyle(color: Colors.orange),
          ),
        ),
      ],
    );
  }
}
