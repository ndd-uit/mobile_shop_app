class OrderItem {
  final String id;
  final String name;
  final int unitPrice;
  final String? imageUrl;
  final int quantity;
  final String? size;
  final String? color;
  final String? style;

  const OrderItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.size,
    this.color,
    this.style,
  });

  int get totalPrice => unitPrice * quantity;
}
