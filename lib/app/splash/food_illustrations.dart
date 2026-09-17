import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small vector illustrations, painted directly: no image downloads or decoding.
class FoodIllustrations extends CustomPainter {
  FoodIllustrations({required this.animation, required this.dark})
    : super(repaint: animation);
  final Animation<double> animation;
  final bool dark;
  static const green = Color(0xFF78A746);
  static const red = Color(0xFFE46C4D);
  static const yellow = Color(0xFFF4C55E);
  static const crust = Color(0xFFCE8942);
  static const cream = Color(0xFFFFE9B8);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.shortestSide / 390).clamp(.65, 1.5);
    final wash = Paint()
      ..color = (dark ? green : const Color(0xFFE4EBCF)).withValues(
        alpha: dark ? .09 : .55,
      );
    canvas.drawCircle(
      Offset(size.width * .03, size.height * .15),
      135 * scale,
      wash,
    );
    canvas.drawCircle(Offset(size.width, size.height * .84), 145 * scale, wash);
    final halo = Paint()
      ..color = green.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(size.center(Offset.zero), size.shortestSide * .43, halo);

    // Intentional asymmetric composition leaves a quiet central brand area.
    final spots = <(double, double, double, double, int)>[
      (.15, .17, -.25, .95, 0), // pizza
      (.82, .20, .23, .9, 1), // burger
      (.96, .43, .15, .64, 2), // drink
      (.06, .74, -.18, .85, 3), // donut
      (.93, .67, .22, .85, 4), // fries
      (size.width > size.height ? .34 : .51, .12, -.4, .50, 5), // carrot
      (.04, .45, -.45, .48, 6), // tomato
      (size.width > size.height ? .88 : .10, .58, -.13, .60, 7), // cupcake
    ];
    for (var i = 0; i < spots.length; i++) {
      final (x, y, rotation, factor, kind) = spots[i];
      final drift =
          math.sin(animation.value * math.pi * 2 + i * .8) * 4 * scale;
      canvas.save();
      canvas.translate(size.width * x, size.height * y + drift);
      canvas.rotate(
        rotation + math.sin(animation.value * math.pi * 2 + i) * .025,
      );
      canvas.scale(scale * factor);
      canvas.drawOval(
        const Rect.fromLTWH(-29, 33, 58, 9),
        Paint()..color = Colors.black.withValues(alpha: dark ? .12 : .035),
      );
      _food(canvas, kind);
      canvas.restore();
    }
    for (final p in [
      const Offset(.30, .26),
      const Offset(.91, .61),
      const Offset(.06, .86),
      const Offset(.71, .10),
    ]) {
      canvas.save();
      canvas.translate(size.width * p.dx, size.height * p.dy);
      canvas.rotate(-.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 15 * scale,
          height: 7 * scale,
        ),
        Paint()..color = green.withValues(alpha: .65),
      );
      canvas.restore();
    }
  }

  void _food(Canvas c, int kind) {
    void oval(Rect rect, Color color) =>
        c.drawOval(rect, Paint()..color = color);
    void box(
      double x,
      double y,
      double w,
      double h,
      Color color, [
      double radius = 5,
    ]) => c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(radius),
      ),
      Paint()..color = color,
    );
    void path(List<Offset> points, Color color) {
      final p = Path()..addPolygon(points, true);
      c.drawPath(p, Paint()..color = color);
    }

    switch (kind) {
      case 0:
        path([
          const Offset(-35, -31),
          const Offset(36, -22),
          const Offset(-9, 39),
        ], yellow);
        final edge = Path()
          ..moveTo(-35, -31)
          ..quadraticBezierTo(0, -38, 36, -22);
        c.drawPath(
          edge,
          Paint()
            ..color = crust
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..strokeCap = StrokeCap.round,
        );
        for (final p in [
          const Offset(-15, -13),
          const Offset(13, -8),
          const Offset(-7, 14),
        ]) {
          c.drawCircle(p, 7, Paint()..color = red);
        }
        box(-3, -20, 4, 9, green, 2);
        box(-21, 3, 4, 8, green, 2);
      case 1:
        oval(const Rect.fromLTWH(-36, -30, 72, 49), yellow);
        box(-37, -2, 74, 10, green);
        box(-33, 6, 66, 11, const Color(0xFF70462F));
        path([
          const Offset(-31, 5),
          const Offset(25, 5),
          const Offset(12, 16),
        ], cream);
        box(-34, 18, 68, 17, crust, 9);
        box(-34, 14, 68, 7, red);
        for (final p in [
          const Offset(-17, -16),
          const Offset(3, -22),
          const Offset(19, -12),
        ]) {
          oval(Rect.fromCenter(center: p, width: 5, height: 2), cream);
        }
      case 2:
        box(5, -51, 5, 28, green, 2);
        path([
          const Offset(-27, -22),
          const Offset(27, -22),
          const Offset(20, 37),
          const Offset(-19, 37),
        ], red);
        box(-30, -26, 60, 8, cream);
        oval(const Rect.fromLTWH(-12, -4, 24, 25), cream);
        oval(const Rect.fromLTWH(-5, 2, 10, 13), green);
      case 3:
        final ring = Paint()
          ..color = crust
          ..style = PaintingStyle.stroke
          ..strokeWidth = 21;
        c.drawCircle(Offset.zero, 25, ring);
        ring
          ..color = const Color(0xFFEFA6A0)
          ..strokeWidth = 16;
        c.drawCircle(const Offset(0, -2), 25, ring);
        for (var i = 0; i < 9; i++) {
          final a = i * math.pi * 2 / 9;
          c.save();
          c.translate(math.cos(a) * 25, math.sin(a) * 25 - 2);
          c.rotate(a + .5);
          box(-1, -3, 3, 7, i.isEven ? cream : yellow, 1);
          c.restore();
        }
      case 4:
        for (var i = 0; i < 6; i++) {
          box(-25 + i * 9, -38 + (i % 3) * 5, 7, 56, yellow, 2);
        }
        path([
          const Offset(-31, -6),
          const Offset(31, -6),
          const Offset(23, 38),
          const Offset(-22, 38),
        ], red);
        oval(const Rect.fromLTWH(-10, 6, 20, 20), cream);
      case 5:
        path([
          const Offset(-16, -15),
          const Offset(18, -12),
          const Offset(-5, 40),
        ], const Color(0xFFF29D4B));
        oval(const Rect.fromLTWH(-15, -36, 13, 28), green);
        oval(const Rect.fromLTWH(0, -39, 13, 30), green);
        box(-9, 0, 15, 3, crust, 1);
        box(-7, 13, 9, 3, crust, 1);
      case 6:
        oval(const Rect.fromLTWH(-28, -22, 56, 51), red);
        for (var i = 0; i < 5; i++) {
          c.save();
          c.translate(0, -19);
          c.rotate(i * math.pi * 2 / 5);
          oval(const Rect.fromLTWH(-4, -16, 8, 19), green);
          c.restore();
        }
        oval(const Rect.fromLTWH(-17, -8, 7, 14), const Color(0xFFF9B09B));
      case 7:
        path([
          const Offset(-28, 0),
          const Offset(28, 0),
          const Offset(20, 34),
          const Offset(-19, 34),
        ], yellow);
        for (var i = 0; i < 4; i++) {
          box(-16 + i * 10, 6, 3, 23, crust, 1);
        }
        oval(const Rect.fromLTWH(-32, -15, 64, 28), const Color(0xFFEFA6A0));
        oval(const Rect.fromLTWH(-22, -31, 44, 30), const Color(0xFFF7C3B7));
        oval(const Rect.fromLTWH(-12, -39, 24, 23), cream);
        c.drawCircle(const Offset(1, -37), 5, Paint()..color = red);
    }
  }

  @override
  bool shouldRepaint(covariant FoodIllustrations oldDelegate) =>
      oldDelegate.dark != dark || oldDelegate.animation != animation;
}
