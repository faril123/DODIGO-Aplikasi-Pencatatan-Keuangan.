import 'package:didigo/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/router/app_router.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class DodigiApp extends ConsumerWidget {
  const DodigiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DODIGI',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: AppRouter.router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final lebar = MediaQuery.sizeOf(context).width;
        if (lebar <= 560) return child; // HP: tidak perlu bingkai

        final pal = context.pal;
        final gelap = Theme.of(context).brightness == Brightness.dark;
        return ColoredBox(
          color: Color.lerp(
            pal.background,
            gelap ? Colors.black : AppColors.primary,
            gelap ? 0.35 : 0.10,
          )!,
          child: Center(
            child: Container(
              width: 520,
              decoration: BoxDecoration(
                color: pal.background,
                border: Border.symmetric(
                  vertical: BorderSide(color: pal.outline, width: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: gelap ? 0.5 : 0.12),
                    blurRadius: 32,
                  ),
                ],
              ),
              child: ClipRect(child: child),
            ),
          ),
        );
      },
    );
  }
}
