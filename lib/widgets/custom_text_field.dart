import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final int minLines;
  final int maxLines;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.minLines = 1,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only allow multiline if not a password field
    final effectiveMinLines = isPassword ? 1 : minLines;
    final effectiveMaxLines = isPassword ? 1 : maxLines;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      minLines: effectiveMinLines,
      maxLines: effectiveMaxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}