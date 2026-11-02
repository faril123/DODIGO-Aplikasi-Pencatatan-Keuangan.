import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'main_bottom_nav.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MainBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          if (index == navigationShell.currentIndex) return;
          navigationShell.goBranch(index);
        },
        onAddTap: () => context.push('/add-transaction'),
      ),
    );
  }
}
