import 'package:flutter/material.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.dependencies});
  final AppDependencies dependencies;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _rememberMe = true;
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final session = await widget.dependencies.authRepository.login(
        email: _email.text,
        password: _password.text,
      );
      await widget.dependencies.session.save(session);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Google Sign-In Logic
  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final session = await widget.dependencies.authService.signInWithGoogle();
      await widget.dependencies.session.save(session);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is Exception ? error.toString().replaceAll('Exception: ', '') : 'Google Sign-In failed.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Welcome Back',
        subtitle: 'Sign in once and we will take you to the right workspace.',
        child: Form(
          key: _formKey,
          child: Column(children: [
            AppTextField(
              controller: _email,
              label: 'Email address',
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email address',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _password,
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !_showPassword,
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
              textInputAction: TextInputAction.done,
              validator: (value) => (value?.length ?? 0) >= 6 ? null : 'Password must be at least 6 characters',
            ),
            Row(children: [
              Checkbox(value: _rememberMe, onChanged: (value) => setState(() => _rememberMe = value ?? true)),
              const Text('Remember me'),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Forgot password?')),
            ]),
            const SizedBox(height: 12),
            AppButton(label: 'Sign in', onPressed: _login, loading: _loading),
            const SizedBox(height: 16),
            
            // OR Divider
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // Google Sign-In Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _googleLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
              label: Text(_googleLoading ? 'Signing in...' : 'Continue with Google'),
              onPressed: (_loading || _googleLoading) ? null : _loginWithGoogle,
            ),
            const SizedBox(height: 18),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Don't have an account?"),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Create one', style: TextStyle(color: AppColors.primaryDark)),
              ),
            ]),
          ]),
        ),
      );
}