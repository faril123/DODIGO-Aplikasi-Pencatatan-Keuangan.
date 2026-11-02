import 'package:flutter/material.dart';

import 'package:didigo/config/router/app_router.dart';
import 'package:didigo/core/theme/app_theme.dart';

class DodigiApp extends StatelessWidget {
  const DodigiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DODIGI',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
