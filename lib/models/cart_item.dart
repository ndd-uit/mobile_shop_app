class CartItem {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final String? size;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.size,
  });

  String get key => '$id-${size ?? ''}';
}
