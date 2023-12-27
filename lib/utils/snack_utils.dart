import 'package:flutter/material.dart';

class SnackUtils {
  static void showSnack(
    BuildContext context, {
    required String message,
    backgroundColor = Colors.red,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: backgroundColor,
      ),
    );
  }
}
