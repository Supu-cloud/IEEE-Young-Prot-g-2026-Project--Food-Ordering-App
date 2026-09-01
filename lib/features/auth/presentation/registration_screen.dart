import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/user_role.dart';
import 'auth_scaffold.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.role, required this.dependencies});
  final UserRole role;
  final AppDependencies dependencies;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _acceptedTerms = false;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _address, _password, _confirmPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the Terms & Conditions.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final message = await widget.dependencies.authRepository.register(
        role: widget.role,
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        address: _address.text,
        password: _password.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline_rounded, size: 48),
          title: Text(widget.role == UserRole.customer ? 'Account created' : 'Application submitted'),
          content: Text(widget.role == UserRole.customer
              ? '$message. You can now sign in.'
              : '$message. You can sign in after an administrator approves your account.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue'))],
        ),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Registration failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? value) => (value?.trim().isEmpty ?? true) ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Join as ${widget.role.label}',
        subtitle: widget.role == UserRole.customer
            ? 'Create your account and start ordering.'
            : 'Submit your details for administrator approval.',
        showBackButton: true,
        child: Form(
          key: _formKey,
          child: Column(children: [
            AppTextField(controller: _name, label: 'Full name', prefixIcon: Icons.person_outline, validator: _required),
            const SizedBox(height: 14),
            AppTextField(
              controller: _email,
              label: 'Email address',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email address',
            ),
            const SizedBox(height: 14),
            AppTextField(controller: _phone, label: 'Phone number', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            AppTextField(controller: _address, label: 'Address', prefixIcon: Icons.location_on_outlined),
            const SizedBox(height: 14),
            AppTextField(
              controller: _password,
              label: 'Password',
              prefixIcon: Icons.lock_outline,
              obscureText: !_showPassword,
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
              validator: (value) => (value?.length ?? 0) >= 6 ? null : 'Use at least 6 characters',
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _confirmPassword,
              label: 'Confirm password',
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: !_showConfirmPassword,
              suffixIcon: IconButton(
                tooltip: _showConfirmPassword ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                icon: Icon(_showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
              validator: (value) => value == _password.text ? null : 'Passwords do not match',
            ),
            CheckboxListTile(
              value: _acceptedTerms,
              onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('I agree to the Terms & Conditions'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: widget.role == UserRole.customer ? 'Create account' : 'Submit application',
              onPressed: _register,
              loading: _loading,
            ),
          ]),
        ),
      );
}
