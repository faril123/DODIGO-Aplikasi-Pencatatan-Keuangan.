import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderWidth;

  const AppCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: borderColor == null
              ? context.pal.border
              : (borderColor == Colors.black
                    ? context.pal.outline
                    : borderColor!),
          width: borderWidth,
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
