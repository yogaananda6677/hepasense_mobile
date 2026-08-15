import 'package:flutter/material.dart';

import '../config/app_config.dart';

class AppConfigScope extends InheritedWidget {
  const AppConfigScope({super.key, required this.config, required super.child});

  final AppConfig config;

  static AppConfig of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppConfigScope>();
    assert(widget != null, 'No AppConfigScope found in context');
    return widget!.config;
  }

  @override
  bool updateShouldNotify(AppConfigScope oldWidget) =>
      config != oldWidget.config;
}
