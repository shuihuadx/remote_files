import 'package:flutter/material.dart';

class SnackUtils {
  static void showSnack(
    BuildContext context, {
    required String message,
    backgroundColor = Colors.red,
    duration = const Duration(seconds: 1),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }
}
