import 'package:flutter/material.dart';

class AiComposer extends StatefulWidget {
  const AiComposer({
    super.key,
    required this.onSend,
    required this.isSubmitting,
  });

  final Future<bool> Function(String message) onSend;
  final bool isSubmitting;

  @override
  State<AiComposer> createState() => _AiComposerState();
}

class _AiComposerState extends State<AiComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final value = _controller.text.trim();
    if (value.isEmpty || widget.isSubmitting) return;
    FocusScope.of(context).unfocus();
    final accepted = await widget.onSend(value);
    if (accepted && mounted) {
      _controller.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('ai-message-input'),
                controller: _controller,
                enabled: !widget.isSubmitting,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Tulis pertanyaan edukatif…',
                  semanticCounterText: 'Maksimal 2000 karakter',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('ai-send-button'),
              tooltip: 'Kirim pesan',
              onPressed: _controller.text.trim().isEmpty || widget.isSubmitting
                  ? null
                  : _send,
              icon: widget.isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
