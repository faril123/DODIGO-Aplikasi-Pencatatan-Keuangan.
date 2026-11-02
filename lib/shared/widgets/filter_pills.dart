import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/theme/app_palette.dart';
import 'pressable_scale.dart';

class FilterPills extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const FilterPills({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = selected == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PressableScale(
              scale: .94,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (sel) return;
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : pal.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppColors.primary : pal.outline,
                      width: 0.5,
                    ),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: 200.ms,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: sel ? const Color(0xFF2B1B10) : pal.textSecondary,
                    ),
                    child: Text(labels[i]),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
