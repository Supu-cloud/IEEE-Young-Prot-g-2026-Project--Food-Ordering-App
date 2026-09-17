import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

class OperationsHeader extends StatelessWidget {
  const OperationsHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String eyebrow, title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
      trailing ?? const SizedBox.shrink(),
    ],
  );
}

class OperationsMetric extends StatelessWidget {
  const OperationsMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });
  final IconData icon;
  final String label, value;
  final String? note;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 21),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        if (note != null)
          Text(
            note!,
            style: const TextStyle(color: AppColors.placeholder, fontSize: 10),
          ),
      ],
    ),
  );
}

class OperationsStatusChip extends StatelessWidget {
  const OperationsStatusChip(this.status, {super.key});
  final String status;

  Color get color => switch (status) {
    'Confirmed' || 'Accepted' || 'Picked Up' => AppColors.primary,
    'Preparing' => AppColors.warning,
    'Out for Delivery' => AppColors.information,
    'Delivered' => AppColors.primaryDark,
    'Cancelled' => AppColors.error,
    _ => AppColors.primaryLight,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: status == 'Cancelled' || status == 'Delivered'
            ? Colors.white
            : AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class MockMapPanel extends StatelessWidget {
  const MockMapPanel({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 245,
    decoration: BoxDecoration(
      color: const Color(0xFFE9EEE5),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _RoadPainter())),
        const Positioned(
          left: 44,
          top: 56,
          child: _MapPin(Icons.storefront, AppColors.primaryDark),
        ),
        const Positioned(
          right: 46,
          bottom: 48,
          child: _MapPin(Icons.location_on, AppColors.error),
        ),
        const Center(
          child: Chip(
            avatar: Icon(Icons.route, size: 17),
            label: Text('Route preview'),
          ),
        ),
      ],
    ),
  );
}

class _MapPin extends StatelessWidget {
  const _MapPin(this.icon, this.color);
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: Colors.white,
    child: Icon(icon, color: color),
  );
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 11
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .7)
        ..quadraticBezierTo(
          size.width * .45,
          size.height * .25,
          size.width,
          size.height * .5,
        ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .25, 0)
        ..lineTo(size.width * .7, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
