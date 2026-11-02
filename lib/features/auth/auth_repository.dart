import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;

  String get displayName {
    final meta = currentUser?.userMetadata;
    final name = (meta?['full_name'] ?? meta?['name']) as String?;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : 'User';
  }

  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'dodigi://login-callback',
    );
  }

  bool get isOnboarded => currentUser?.userMetadata?['onboarded'] == true;

  Future<void> completeOnboarding() async {
    await _supabase.auth.updateUser(UserAttributes(data: {'onboarded': true}));
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
