import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_localizations.dart';

class LanguageController extends ChangeNotifier {
  LanguageController({FlutterSecureStorage? storage, this.onChanged}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  final Future<void> Function(Locale)? onChanged;
  Locale locale = const Locale('en');
  Future<void> restore() async { final value = await _storage.read(key: 'language_code'); locale = supportedLanguages.firstWhere((item) => item.languageCode == value, orElse: () => const Locale('en')); notifyListeners(); }
  Future<void> setLocale(Locale value) async { await _storage.write(key: 'language_code', value: value.languageCode); locale = value; notifyListeners(); try { await onChanged?.call(value); } catch (_) {} }
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, required this.controller});
  final LanguageController controller;
  @override Widget build(BuildContext context) => ListenableBuilder(listenable: controller, builder: (context, _) => DropdownButtonFormField<Locale>(
    initialValue: controller.locale,
    decoration: InputDecoration(labelText: AppLocalizations.of(context).t('language'), prefixIcon: const Icon(Icons.language)),
    items: const [DropdownMenuItem(value: Locale('en'), child: Text('English')), DropdownMenuItem(value: Locale('si'), child: Text('සිංහල')), DropdownMenuItem(value: Locale('ta'), child: Text('தமிழ்'))],
    onChanged: (value) { if (value != null) controller.setLocale(value); },
  ));
}
