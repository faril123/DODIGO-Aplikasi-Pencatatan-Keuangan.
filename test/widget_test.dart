import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:didigo/app.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      // ignore: deprecated_member_use
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('DodigiApp shows splash screen on start', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DodigiApp()));

    // Splash page menampilkan loading indicator saat pertama kali dibuka.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Habiskan delay 1 detik di SplashPage supaya tidak ada timer yang tertinggal.
    await tester.pump(const Duration(seconds: 1));
  });
}
