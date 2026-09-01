import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.create();
  await dependencies.session.restore();
  runApp(FoodOrderingApp(dependencies: dependencies));
}
