import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isGlowy; // New property to enable/disable glow effect
  final bool isDarkMode; // Add property to handle theme-based glow

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.isGlowy = false, // Default is false
    this.isDarkMode = true, // Default is dark mode enabled
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = isDarkMode ? Colors.blueAccent : Colors.orangeAccent;

    return Container(
      decoration: isGlowy
          ? BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      )
          : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}