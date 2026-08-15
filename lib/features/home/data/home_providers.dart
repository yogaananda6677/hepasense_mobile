import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/home_state.dart';
import '../presentation/controllers/home_controller.dart';

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
