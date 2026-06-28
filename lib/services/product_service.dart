import 'supabase_client.dart';
import '../models/product.dart';

class ProductService {
  /// Lấy tất cả sản phẩm từ Supabase. Không fallback mock.
  static Future<List<Product>> fetchAll() async {
    final data = await supabase
        .from('products')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToProduct)
        .toList();
  }

  /// Admin: lấy cả sản phẩm đang bán và đã ẩn.
  static Future<List<Product>> fetchAdminAll() async {
    final data = await supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToProduct)
        .toList();
  }

  static Future<Product?> fetchById(String id) async {
    final data = await supabase
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return _rowToProduct(data);
  }

  static Future<void> upsertProduct({
    required String id,
    required String name,
    required int price,
    int? oldPrice,
    required String category,
    required String imageUrl,
    required List<String> imageUrls,
    required String description,
    required int stock,
    required bool isActive,
  }) async {
    await supabase.from('products').upsert({
      'id': id,
      'name': name,
      'price': price,
      'old_price': oldPrice,
      'category': category,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'description': description,
      'stock': stock,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> setActive({
    required String id,
    required bool isActive,
  }) async {
    await supabase
        .from('products')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Lấy sản phẩm theo category.
  static Future<List<Product>> fetchByCategory(String category) async {
    final data = await supabase
        .from('products')
        .select()
        .eq('category', category)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToProduct)
        .toList();
  }

  static Product _rowToProduct(Map<String, dynamic> row) {
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      price: row['price'] as int,
      oldPrice: row['old_price'] as int?,
      category: row['category'] as String,
      imageUrl: row['image_url'] as String,
      imageUrls: _readImageUrls(row),
      description: row['description'] as String,
      rating: (row['rating'] as num).toDouble(),
      stock: row['stock'] as int? ?? 0,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  static List<String> _readImageUrls(Map<String, dynamic> row) {
    final raw = row['image_urls'];
    if (raw is List) return raw.whereType<String>().toList();
    final imageUrl = row['image_url'] as String? ?? '';
    return imageUrl.isEmpty ? const [] : [imageUrl];
  }
}
