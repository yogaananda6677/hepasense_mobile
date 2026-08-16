import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/routes.dart';
import '../theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('shared-bottom-navigation'),
      decoration: BoxDecoration(
        color: AppColors.navigationBackground,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final location = switch (index) {
            0 => AppRoutes.home,
            1 => AppRoutes.screeningHistory,
            2 => AppRoutes.education,
            3 => AppRoutes.aiAssistant,
            _ => AppRoutes.account,
          };
          if (index != selectedIndex) context.go(location);
        },
        destinations: [
          _destination(Icons.home_outlined, Icons.home, 'Beranda', 0),
          _destination(Icons.history_outlined, Icons.history, 'Riwayat', 1),
          _destination(Icons.restaurant_outlined, Icons.restaurant, 'Gizi', 2),
          _destination(
            Icons.chat_bubble_outline,
            Icons.chat_bubble,
            'Chat AI',
            3,
          ),
          _destination(Icons.person_outline, Icons.person, 'Akun', 4),
        ],
      ),
    );
  }

  NavigationDestination _destination(
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
  ) => NavigationDestination(
    icon: Icon(icon, color: AppColors.onSurfaceVariant),
    selectedIcon: Icon(selectedIcon, color: AppColors.primary),
    label: label,
  );
}
