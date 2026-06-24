import 'supabase_client.dart';
import '../models/product.dart';

class ProductService {
  /// Lấy tất cả sản phẩm từ Supabase. Không fallback mock.
  static Future<List<Product>> fetchAll() async {
    final data = await supabase
        .from('products')
        .select()
        .order('id', ascending: true);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToProduct)
        .toList();
  }

  /// Lấy sản phẩm theo category.
  static Future<List<Product>> fetchByCategory(String category) async {
    final data = await supabase
        .from('products')
        .select()
        .eq('category', category)
        .order('id', ascending: true);

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
      description: row['description'] as String,
      rating: (row['rating'] as num).toDouble(),
    );
  }
}
