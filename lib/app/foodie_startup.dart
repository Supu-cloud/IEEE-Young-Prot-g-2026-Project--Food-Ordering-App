import 'package:flutter/material.dart';

import '../core/di/app_dependencies.dart';
import '../core/theme/app_theme.dart';
import 'app.dart';
import 'splash/foodie_splash.dart';

/// Draws immediately while the existing session and payment setup runs.
class FoodieStartup extends StatefulWidget {
  const FoodieStartup({
    super.key,
    required this.dependencies,
    required this.initialize,
    this.minimumDisplay = const Duration(milliseconds: 1100),
  });

  final AppDependencies dependencies;
  final Future<void> Function() initialize;
  final Duration minimumDisplay;

  @override
  State<FoodieStartup> createState() => _FoodieStartupState();
}

class _FoodieStartupState extends State<FoodieStartup> {
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _failed = false);
    try {
      await Future.wait([
        widget.initialize(),
        Future<void>.delayed(widget.minimumDisplay),
      ]);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return FoodOrderingApp(dependencies: widget.dependencies);
    return ListenableBuilder(
      listenable: widget.dependencies.theme,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: FoodieSplash(onRetry: _failed ? _start : null),
      ),
    );
  }
}
