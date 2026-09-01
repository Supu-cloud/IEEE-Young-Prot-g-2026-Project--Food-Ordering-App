import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppStatus { confirmed, preparing, outForDelivery, delivered, cancelled, pending }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AppStatus.confirmed => ('Confirmed', AppColors.primary),
      AppStatus.preparing => ('Preparing', AppColors.warning),
      AppStatus.outForDelivery => ('Out for delivery', AppColors.information),
      AppStatus.delivered => ('Delivered', AppColors.primaryDark),
      AppStatus.cancelled => ('Cancelled', AppColors.error),
      AppStatus.pending => ('Pending', AppColors.primaryLight),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: .2),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
