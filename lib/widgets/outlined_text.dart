import 'package:flutter/material.dart';

class OutlinedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color outlineColor;
  final double outlineWidth;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const OutlinedText({
    super.key,
    required this.text,
    this.style,
    this.outlineColor = Colors.black,
    this.outlineWidth = 2,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outline
        Text(
          text,
          style: (style ?? DefaultTextStyle.of(context).style).copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..color = outlineColor,
          ),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
        // Fill
        Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ],
    );
  }
}