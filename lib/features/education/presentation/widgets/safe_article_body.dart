import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';

/// Displays the backend's Markdown-style text without interpreting HTML,
/// links, scripts, images, or other executable/interactive content.
class SafeArticleBody extends StatelessWidget {
  const SafeArticleBody({super.key, required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final blocks = content.replaceAll('\r\n', '\n').split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final line in blocks) _line(context, line)],
    );
  }

  Widget _line(BuildContext context, String raw) {
    final line = _plainText(raw.trimRight());
    if (line.trim().isEmpty) return const SizedBox(height: AppSpacing.sm);
    if (line.startsWith('### ')) {
      return _text(context, line.substring(4), 3);
    }
    if (line.startsWith('## ')) {
      return _text(context, line.substring(3), 2);
    }
    if (line.startsWith('# ')) {
      return _text(context, line.substring(2), 1);
    }
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(child: Text('•  ')),
            Expanded(child: Text(line.substring(2))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(line, style: Theme.of(context).textTheme.bodyLarge),
    );
  }

  Widget _text(BuildContext context, String value, int level) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(
        value,
        style: level == 1
            ? Theme.of(context).textTheme.headlineSmall
            : Theme.of(context).textTheme.titleLarge,
      ),
    ),
  );

  String _plainText(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('**', '')
      .replaceAll('__', '')
      .replaceAll('`', '');
}
