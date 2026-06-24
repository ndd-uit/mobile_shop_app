import 'supabase_client.dart';
import 'auth_service.dart';

class FavoriteService {
  /// Lấy danh sách product_id yêu thích của user hiện tại.
  static Future<Set<String>> fetchIds() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return {};

    final rows = await supabase
        .from('favorites')
        .select('product_id')
        .eq('user_id', uid);

    return (rows as List).map((r) => r['product_id'] as String).toSet();
  }

  /// Thêm sản phẩm vào yêu thích.
  static Future<void> add(String productId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await supabase.from('favorites').upsert({
      'user_id': uid,
      'product_id': productId,
    });
  }

  /// Xóa sản phẩm khỏi yêu thích.
  static Future<void> remove(String productId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', uid)
        .eq('product_id', productId);
  }

  /// Toggle: thêm nếu chưa có, xóa nếu đã có.
  static Future<void> toggle(String productId, bool isCurrentlyFavorite) async {
    if (isCurrentlyFavorite) {
      await remove(productId);
    } else {
      await add(productId);
    }
  }
}
