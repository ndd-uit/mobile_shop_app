import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';

class AuthService {
  /// Đăng ký tài khoản mới.
  /// Supabase Auth dùng email, nên ta tạo email ảo từ số điện thoại.
  static Future<AuthResponse> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final fakeEmail = '$phone@users.daisyshop.app';

    final response = await supabase.auth.signUp(
      email: fakeEmail,
      password: password,
      data: {'name': name, 'phone_number': phone},
    );

    if (response.session == null) {
      throw const AuthException(
        'Supabase đang bật xác nhận email. Hãy tắt Confirm email vì ứng dụng đăng nhập bằng số điện thoại.',
      );
    }

    return response;
  }

  /// Đăng nhập bằng số điện thoại + mật khẩu.
  static Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    final fakeEmail = '$phone@users.daisyshop.app';

    return supabase.auth.signInWithPassword(
      email: fakeEmail,
      password: password,
    );
  }

  static Future<void> sendPasswordResetForPhone(String phone) async {
    final fakeEmail = '$phone@users.daisyshop.app';
    await supabase.auth.resetPasswordForEmail(fakeEmail);
  }

  /// Đăng xuất.
  static Future<void> logout() async {
    await supabase.auth.signOut();
  }

  /// User hiện tại (null nếu chưa đăng nhập).
  static User? get currentUser => supabase.auth.currentUser;

  /// ID user hiện tại.
  static String? get currentUserId => supabase.auth.currentUser?.id;
}
