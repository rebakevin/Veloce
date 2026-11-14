import 'package:flutter/material.dart';

/// The app bar's back arrow, shared so every screen labels it the same way.
class AppBackButton extends StatelessWidget {
  const AppBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: onPressed,
    );
  }
}
