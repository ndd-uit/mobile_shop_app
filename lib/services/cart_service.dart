import 'supabase_client.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'auth_service.dart';

class CartService {
  /// Lấy giỏ hàng từ Supabase, join với products để lấy thông tin đầy đủ.
  static Future<List<CartItem>> fetchAll() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return [];

    final rows = await supabase
        .from('cart_items')
        .select('id, product_id, size, quantity, products(name, price, image_url)')
        .eq('user_id', uid)
        .order('created_at', ascending: true);

    return (rows as List).map((row) {
      final product = row['products'] as Map<String, dynamic>;
      return CartItem(
        id: row['product_id'] as String,
        name: product['name'] as String,
        price: product['price'] as int,
        imageUrl: product['image_url'] as String,
        quantity: row['quantity'] as int,
        size: row['size'] as String?,
      );
    }).toList();
  }

  /// Thêm hoặc tăng số lượng sản phẩm trong giỏ.
  static Future<void> addOrIncrement(Product product, String size) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    // Kiểm tra đã có chưa
    final existing = await supabase
        .from('cart_items')
        .select('id, quantity')
        .eq('user_id', uid)
        .eq('product_id', product.id)
        .eq('size', size)
        .maybeSingle();

    if (existing != null) {
      await supabase
          .from('cart_items')
          .update({'quantity': (existing['quantity'] as int) + 1})
          .eq('id', existing['id']);
    } else {
      await supabase.from('cart_items').insert({
        'user_id': uid,
        'product_id': product.id,
        'size': size,
        'quantity': 1,
      });
    }
  }

  /// Cập nhật số lượng. Nếu quantity <= 0 thì xóa.
  static Future<void> updateQuantity(
    String productId,
    String size,
    int quantity,
  ) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    if (quantity <= 0) {
      await remove(productId, size);
      return;
    }

    await supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('user_id', uid)
        .eq('product_id', productId)
        .eq('size', size);
  }

  /// Xóa một item khỏi giỏ.
  static Future<void> remove(String productId, String size) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await supabase
        .from('cart_items')
        .delete()
        .eq('user_id', uid)
        .eq('product_id', productId)
        .eq('size', size);
  }

  /// Xóa toàn bộ giỏ hàng (sau khi đặt hàng thành công).
  static Future<void> clearAll() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await supabase.from('cart_items').delete().eq('user_id', uid);
  }
}
