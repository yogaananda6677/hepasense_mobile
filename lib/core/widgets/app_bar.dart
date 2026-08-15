import 'package:flutter/material.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null ? Text(title!) : null,
      leading: showBackButton
          ? leading ??
                (Navigator.canPop(context)
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null)
          : leading,
      actions: actions,
    );
  }
}
