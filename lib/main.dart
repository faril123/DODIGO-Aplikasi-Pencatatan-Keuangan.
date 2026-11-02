// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/notification/notification_service.dart';
import 'features/Splash Screen/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _Bootstrap()));
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late final Future<void> _init = _initialize();

  Future<void> _initialize() async {
    await dotenv.load(fileName: ".env");
    await initializeDateFormatting('id_ID');
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    // Notifikasi tidak boleh menahan startup (ada dialog izin di dalamnya).
    unawaited(NotificationService.instance.init().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snap) {
        if (snap.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal memulai aplikasi: ${snap.error}'),
                ),
              ),
            ),
          );
        }
        if (snap.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const SplashView(),
          );
        }
        return const DodigiApp();
      },
    );
  }
}
