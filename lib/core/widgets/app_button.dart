import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';

enum AppButtonVariant { primary, secondary, outline }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String text;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (isEnabled && !isLoading) ? onPressed : null;

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          child: _buildChild(context),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          child: _buildChild(context),
        );
      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          child: _buildChild(context),
        );
    }
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
