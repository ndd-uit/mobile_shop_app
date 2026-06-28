import '../../services/supabase_client.dart';

class AdminAuthService {
  static bool get isSignedIn => supabase.auth.currentSession != null;

  static Future<bool> hasAdminSession() async {
    final session = supabase.auth.currentSession;
    if (session == null) return false;

    if (await isCurrentUserAdmin()) return true;
    await supabase.auth.signOut();
    return false;
  }

  static Future<bool> isCurrentUserAdmin() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final result = await supabase.rpc('is_admin');
    return result == true;
  }

  static Future<void> login({
    required String username,
    required String password,
  }) async {
    final email = username.trim().toLowerCase();
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null || !await isCurrentUserAdmin()) {
      await supabase.auth.signOut();
      throw const AdminAuthException('Tài khoản này chưa được cấp quyền admin');
    }
  }

  static Future<void> logout() async {
    await supabase.auth.signOut();
  }
}

class AdminAuthException implements Exception {
  final String message;

  const AdminAuthException(this.message);

  @override
  String toString() => message;
}
