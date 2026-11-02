import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';

class MainBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;
  final bool addButtonAktif;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
    this.addButtonAktif = false,
  });

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Beranda'),
    (Icons.history_rounded, Icons.history, 'Riwayat'),
    (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Analitik'),
    (Icons.person_rounded, Icons.person_outline, 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: context.pal.card.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: context.pal.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  filledIcon: _items[0].$1,
                  outlineIcon: _items[0].$2,
                  label: _items[0].$3,
                  selected: widget.currentIndex == 0,
                  onTap: () => widget.onTap(0),
                ),
                _NavItem(
                  filledIcon: _items[1].$1,
                  outlineIcon: _items[1].$2,
                  label: _items[1].$3,
                  selected: widget.currentIndex == 1,
                  onTap: () => widget.onTap(1),
                ),
                _AddButton(
                  onTap: widget.onAddTap,
                  aktif: widget.addButtonAktif,
                ),
                _NavItem(
                  filledIcon: _items[2].$1,
                  outlineIcon: _items[2].$2,
                  label: _items[2].$3,
                  selected: widget.currentIndex == 2,
                  onTap: () => widget.onTap(2),
                ),
                _NavItem(
                  filledIcon: _items[3].$1,
                  outlineIcon: _items[3].$2,
                  label: _items[3].$3,
                  selected: widget.currentIndex == 3,
                  onTap: () => widget.onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData filledIcon;
  final IconData outlineIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.filledIcon,
    required this.outlineIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _wiggle;
  late final Animation<double> _ripple;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..value = 1.0;

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.88,
          end: 1.06,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.06,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
    ]).animate(_controller);

    _wiggle =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.05), weight: 20),
          TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.25, 0.75),
          ),
        );

    _ripple = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pop() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? context.pal.primaryDark
        : context.pal.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pop,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _wiggle.value,
            child: Transform.scale(scale: _scale.value, child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 52,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ripple,
                    builder: (context, _) {
                      return Container(
                        width: 36 + 16 * _ripple.value,
                        height: 36 + 16 * _ripple.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(
                            alpha: (1 - _ripple.value).clamp(0, 1) * 0.25,
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.selected
                          ? context.pal.primaryLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        widget.selected
                            ? widget.filledIcon
                            : widget.outlineIcon,
                        key: ValueKey(widget.selected),
                        color: color,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: color,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool aktif;

  const _AddButton({required this.onTap, required this.aktif});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _ripple;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1.0;

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.1,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
    ]).animate(_controller);

    _ripple = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pop() {
    HapticFeedback.mediumImpact();
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pop,
      child: SizedBox(
        width: 70,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _ripple,
              builder: (context, _) {
                return Container(
                  width: 46 + 24 * _ripple.value,
                  height: 46 + 24 * _ripple.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: (1 - _ripple.value).clamp(0, 1) * 0.3,
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _scale,
              builder: (context, child) {
                return Transform.scale(scale: _scale.value, child: child);
              },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  turns: widget.aktif ? 0.125 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
