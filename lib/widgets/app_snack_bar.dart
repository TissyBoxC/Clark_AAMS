import 'package:flutter/material.dart';

class AppSnackBar {
  const AppSnackBar._();

  static const duration = Duration(seconds: 2);

  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: duration, action: action),
      );
  }
}
