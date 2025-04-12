import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> handleAnonymousLogin() async {
    try {
      // Sign in anonymously using Supabase's built-in method
      final response = await _supabase.auth.signInAnonymously();
      if (response.user == null) throw Exception('Anonymous login failed');

      // Upsert user in public.users table
      await _supabase.from('users').upsert({
        'id': response.user!.id,
        'created_at': DateTime.now().toIso8601String(),
        'is_anonymous': true,
        'last_active': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  String? get currentUserId => _supabase.auth.currentUser?.id;
}