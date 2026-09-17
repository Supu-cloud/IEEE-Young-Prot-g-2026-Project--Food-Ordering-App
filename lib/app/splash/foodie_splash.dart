import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'food_illustrations.dart';

class FoodieSplash extends StatefulWidget {
  const FoodieSplash({super.key, this.onRetry});
  final VoidCallback? onRetry;
  static const developerCredit =
      'Developed by Soft. Dev | G 04 for Young Protégé 2026.';

  @override
  State<FoodieSplash> createState() => _FoodieSplashState();
}

class _FoodieSplashState extends State<FoodieSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    const background = Color(0xFF101D16);
    const ink = Color(0xFFF5F3E6);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: background,
      ),
      child: Scaffold(
        backgroundColor: background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 550;
            return Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: FoodIllustrations(
                        animation: _motion,
                        dark: true,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 42,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        if (constraints.maxHeight >= 650)
                          Text(
                            'FRESH FINDS. HAPPY BITES.',
                            style: TextStyle(
                              color: ink.withValues(alpha: .65),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                            ),
                          ),
                        Expanded(
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(
                                milliseconds: reduced ? 0 : 700,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 14),
                                  child: child,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: 280,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: compact ? 74 : 98,
                                        height: compact ? 74 : 98,
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2C432C),
                                          borderRadius: BorderRadius.circular(
                                            32,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: .09,
                                              ),
                                              blurRadius: 30,
                                              offset: const Offset(0, 12),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          child: Image.asset(
                                            'assets/branding/app_logo.png',
                                            cacheWidth: 256,
                                            excludeFromSemantics: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Image.asset(
                                        'assets/branding/sri_lanka_flag.png',
                                        width: 28,
                                        height: 14,
                                        semanticLabel: 'Sri Lanka',
                                        filterQuality: FilterQuality.medium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Foodie',
                                        style: TextStyle(
                                          color: ink,
                                          fontSize: 68,
                                          height: 1.05,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -3.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: 36,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'A little craving.\nA lot to love.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: ink.withValues(alpha: .8),
                                          fontSize: 19,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.onRetry != null) ...[
                          Text(
                            'Could not finish starting Foodie.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ink, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: widget.onRetry,
                            child: const Text('Try again'),
                          ),
                        ] else ...[
                          Semantics(
                            label: 'Starting Foodie',
                            liveRegion: true,
                            child: ExcludeSemantics(
                              child: AnimatedBuilder(
                                animation: _motion,
                                builder: (context, _) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    3,
                                    (i) => Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary.withValues(
                                          alpha: reduced
                                              ? .8
                                              : .35 +
                                                    .65 *
                                                        ((math.sin(
                                                                  _motion.value *
                                                                          math.pi *
                                                                          2 -
                                                                      i,
                                                                ) +
                                                                1) /
                                                            2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Good food is on its way',
                            style: TextStyle(
                              color: ink.withValues(alpha: .65),
                              fontSize: 12,
                              letterSpacing: .3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          FoodieSplash.developerCredit,
                          key: const Key('splash-developer-credit'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ink.withValues(alpha: .75),
                            fontSize: 11,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
