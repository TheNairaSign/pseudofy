import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PseudocodeView extends StatelessWidget {
  const PseudocodeView({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy',
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
          ),
        ),
      ],
    );
  }
}
