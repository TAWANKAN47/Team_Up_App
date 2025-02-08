// lib/widgets/custom_popup.dart
import 'package:flutter/material.dart';

class CustomPopup extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const CustomPopup({
    Key? key,
    required this.title,
    required this.message,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.orange[50],
      title: Text(
        title,
        style: TextStyle(
          color: Colors.orange[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(color: Colors.orange[700]),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: onClose,
          child: const Text(
            "ตกลง",
            style: TextStyle(color: Colors.orange),
          ),
        ),
      ],
    );
  }
}
