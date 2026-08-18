import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Code tab: language dropdown (built from the resolved solution's
/// available templates) + selectable/copyable source.
class CodeView extends StatefulWidget {
  const CodeView({super.key, required this.code});
  final Map<String, String> code;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  late String _language;

  @override
  void initState() {
    super.initState();
    _language = widget.code.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.code.isEmpty) {
      return const Center(child: Text('No code template available for this variant yet.'));
    }
    final source = widget.code[_language] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              DropdownButton<String>(
                value: _language,
                items: [
                  for (final lang in widget.code.keys)
                    DropdownMenuItem(value: lang, child: Text(lang)),
                ],
                onChanged: (value) => setState(() => _language = value!),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy code',
                onPressed: () => Clipboard.setData(ClipboardData(text: source)),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SelectableText(
              source,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
