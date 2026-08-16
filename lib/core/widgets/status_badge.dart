import 'package:flutter/material.dart';

import '../errors/status_mapping.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ScreenStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconData(), size: 16, color: _textColor(context)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              StatusMapping.labelFor(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: _textColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  Color _backgroundColor(BuildContext context) {
    switch (status) {
      case ScreenStatus.healthy:
        return AppColors.statusHealthySurface;
      case ScreenStatus.warning:
        return AppColors.statusWarningSurface;
      case ScreenStatus.highRisk:
        return AppColors.statusHighRiskSurface;
      case ScreenStatus.invalid:
        return AppColors.statusInvalidSurface;
    }
  }

  Color _textColor(BuildContext context) {
    switch (status) {
      case ScreenStatus.healthy:
        return AppColors.statusHealthy;
      case ScreenStatus.warning:
        return AppColors.statusWarning;
      case ScreenStatus.highRisk:
        return AppColors.statusHighRisk;
      case ScreenStatus.invalid:
        return AppColors.statusInvalid;
    }
  }

  IconData _iconData() {
    switch (status) {
      case ScreenStatus.healthy:
        return Icons.check_circle;
      case ScreenStatus.warning:
        return Icons.warning;
      case ScreenStatus.highRisk:
        return Icons.error;
      case ScreenStatus.invalid:
        return Icons.help_outline;
    }
  }
}
