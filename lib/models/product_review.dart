class ProductReview {
  final String productId;
  final String orderId;
  final int rating;
  final String comment;
  final List<String> imagePaths;
  final DateTime createdAt;

  const ProductReview({
    required this.productId,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.imagePaths,
    required this.createdAt,
  });
}
