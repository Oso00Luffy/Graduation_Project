import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for clipboard functionality

class ShowMoreText extends StatefulWidget {
  final String text;
  final int maxLines;

  ShowMoreText({required this.text, this.maxLines = 5});

  @override
  _ShowMoreTextState createState() => _ShowMoreTextState();
}

class _ShowMoreTextState extends State<ShowMoreText> {
  bool _isExpanded = false;
  late bool _isLongText;

  @override
  void initState() {
    super.initState();
    _isLongText = widget.text.length > 100; // Adjust this threshold as needed
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _isExpanded
            ? ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: SelectableText(
              widget.text,
              style: TextStyle(fontSize: 16),
            ),
          ),
        )
            : SelectableText(
          widget.text,
          maxLines: widget.maxLines,
          style: TextStyle(fontSize: 16),
        ),
        if (_isLongText)
          GestureDetector(
            onTap: _toggleExpand,
            child: Text(
              _isExpanded ? 'Show Less' : 'Show More',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: _copyToClipboard,
          child: Text('Copy to Clipboard'),
        ),
      ],
    );
  }
}