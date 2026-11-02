import 'package:didigo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/login_page.dart';
import '../../features/onboarding/wallet_setup_page.dart';
import '../../features/dashboard_page.dart';
import '../../features/Splash Screen/splash_page.dart';
import '../../features/transaction/transaction_form_page.dart';
import '../../features/transaction/history_page.dart';
import '../../features/analytics/analytics_page.dart';
import '../../features/account/account_page.dart';
import '../../features/account/notification_setting_page.dart';
import '../../features/wallet/wallet_management_page.dart';
import '../../features/Financial_Tools_Menu/Target/target_page.dart';
import '../../features/Financial_Tools_Menu/Tagihan/tagihan_page.dart';
import '../../features/Financial_Tools_Menu/Budget/budget_page.dart';
import '../../features/Financial_Tools_Menu/Laporan/laporan_page.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/widgets/main_shell.dart';

import 'refresh_stream.dart';

class AppRouter {
  AppRouter._();

  static const _publicRoutes = {'/', '/login'};

  static final router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final client = Supabase.instance.client;
      final loggedIn = client.auth.currentSession != null;
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      if (!loggedIn && !isPublic) return '/login';

      if (loggedIn) {
        final onboarded =
            client.auth.currentUser?.userMetadata?['onboarded'] == true;

        if (!onboarded && location != '/wallet-setup') return '/wallet-setup';
        if (onboarded && location == '/wallet-setup') return '/dashboard';
        if (location == '/login') {
          return onboarded ? '/dashboard' : '/wallet-setup';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            Theme(data: AppTheme.light, child: const LoginPage()),
      ),
      GoRoute(
        path: '/wallet-setup',
        builder: (context, state) => const WalletSetupPage(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) =>
            TransactionFormPage(existing: state.extra as TransactionModel?),
      ),
      GoRoute(path: '/target', builder: (context, state) => const TargetPage()),
      GoRoute(
        path: '/tagihan',
        builder: (context, state) => const TagihanPage(),
      ),
      GoRoute(path: '/budget', builder: (context, state) => const BudgetPage()),
      GoRoute(
        path: '/notifikasi',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/laporan',
        builder: (context, state) => const LaporanPage(),
      ),
      GoRoute(
        path: '/wallets',
        builder: (context, state) => const WalletManagementPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
