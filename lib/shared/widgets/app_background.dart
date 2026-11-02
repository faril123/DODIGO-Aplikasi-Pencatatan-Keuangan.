import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' show PointMode;
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// Latar halaman: cahaya amber yang melayang pelan + pola titik halus.
/// Pakai sebagai pembungkus body: AppBackground(child: ...).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glowAlpha = dark ? .10 : .22;
    final dotColor = context.pal.textPrimary.withValues(
      alpha: dark ? .05 : .045,
    );

    return Stack(
      children: [
        // RepaintBoundary: lapisan ini tidak digambar ulang saat list scroll.
        Positioned.fill(
          child: RepaintBoundary(
            child: Stack(
              children: [
                Positioned(
                  top: -120,
                  right: -100,
                  child: _Glow(size: 320, alpha: glowAlpha)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .move(
                        begin: Offset.zero,
                        end: const Offset(-30, 40),
                        duration: 7.seconds,
                        curve: Curves.easeInOut,
                      ),
                ),
                Positioned(
                  top: 380,
                  left: -150,
                  child: _Glow(size: 300, alpha: glowAlpha * .7)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .move(
                        begin: Offset.zero,
                        end: const Offset(30, -30),
                        duration: 9.seconds,
                        curve: Curves.easeInOut,
                      ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _DotsPainter(dotColor)),
                  ),
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: alpha),
            AppColors.primary.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 22.0;
    final points = <Offset>[
      for (double y = gap / 2; y < size.height; y += gap)
        for (double x = gap / 2; x < size.width; x += gap) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}
