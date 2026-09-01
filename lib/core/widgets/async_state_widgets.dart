import 'package:flutter/material.dart';

import 'app_button.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message = 'Loading...'});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(message),
        ]),
      );
}

class AppError extends StatelessWidget {
  const AppError({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              AppButton(label: 'Try again', onPressed: onRetry),
            ],
          ]),
        ),
      );
}
