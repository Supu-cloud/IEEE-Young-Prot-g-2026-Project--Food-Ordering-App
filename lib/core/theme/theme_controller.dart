import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../localization/app_localizations.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({FlutterSecureStorage? storage, this.onChanged})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  final Future<void> Function(ThemeMode)? onChanged;
  ThemeMode mode = ThemeMode.system;
  Future<void> restore() async {
    String? saved;
    try {
      saved = await _storage.read(key: 'theme_mode');
    } catch (_) {
      /* Keep the system theme if storage is unavailable. */
    }
    mode =
        ThemeMode.values.where((value) => value.name == saved).firstOrNull ??
        ThemeMode.system;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    await _storage.write(key: 'theme_mode', value: value.name);
    mode = value;
    notifyListeners();
    try { await onChanged?.call(value); } catch (_) { /* local preference remains usable offline */ }
  }
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key, required this.controller});
  final ThemeController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => DropdownButtonFormField<ThemeMode>(
      key: ValueKey(controller.mode),
      initialValue: controller.mode,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).t('theme'),
        prefixIcon: Icon(Icons.brightness_6_outlined),
      ),
      items: [
        DropdownMenuItem(
          value: ThemeMode.system,
          child: Text(AppLocalizations.of(context).t('system')),
        ),
        DropdownMenuItem(value: ThemeMode.light, child: Text(AppLocalizations.of(context).t('light'))),
        DropdownMenuItem(value: ThemeMode.dark, child: Text(AppLocalizations.of(context).t('dark'))),
      ],
      onChanged: (value) async {
        if (value == null) return;
        try {
          await controller.setMode(value);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).t('save_error')),
              ),
            );
          }
        }
      },
    ),
  );
}
