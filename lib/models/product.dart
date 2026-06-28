class Product {
  final String id;
  final String name;
  final int price;
  final int? oldPrice;
  final String category;
  final String imageUrl;
  final List<String> imageUrls;
  final String description;
  final double rating;
  final int stock;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    required this.category,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.description,
    required this.rating,
    this.stock = 999999,
    this.isActive = true,
  });

  /// Returns the discount percentage if oldPrice is set, else null.
  int? get discountPercent {
    if (oldPrice == null || oldPrice! <= price) return null;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }
}
