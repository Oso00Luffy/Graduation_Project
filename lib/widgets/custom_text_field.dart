import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final int minLines;
  final int maxLines;
  final TextStyle? style;
  final TextStyle? hintStyle;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.style,
    this.hintStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveStyle = style ??
        TextStyle(
          color: theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87),
        );
    final effectiveHintStyle = hintStyle ??
        TextStyle(
          color: isDark ? Colors.white54 : Colors.black26,
        );
    final fillColor = isDark ? const Color(0xFF22242A) : Colors.white;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      minLines: isPassword ? 1 : minLines,
      maxLines: isPassword ? 1 : maxLines,
      style: effectiveStyle,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: effectiveHintStyle,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}