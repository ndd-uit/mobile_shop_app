import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import '../models/product_review.dart';
import 'auth_service.dart';

class ReviewService {
  static const _bucket = 'review-images';

  /// Lấy tất cả đánh giá của user hiện tại.
  static Future<List<ProductReview>> fetchByUser() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return [];

    final rows = await supabase
        .from('reviews')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToReview)
        .toList();
  }

  /// Lấy tất cả đánh giá của một sản phẩm (tất cả users), join tên người đánh giá.
  static Future<List<ProductReview>> fetchByProduct(String productId) async {
    final rows = await supabase
        .from('reviews')
        .select('*, profiles(name)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToReviewWithName)
        .toList();
  }

  /// Kiểm tra user đã đánh giá sản phẩm trong đơn hàng chưa.
  static Future<bool> hasReviewed({
    required String productId,
    required String orderId,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return false;

    final row = await supabase
        .from('reviews')
        .select('id')
        .eq('user_id', uid)
        .eq('product_id', productId)
        .eq('order_id', orderId)
        .maybeSingle();

    return row != null;
  }

  /// Upload ảnh local lên Supabase Storage, trả về danh sách public URL.
  static Future<List<String>> _uploadImages({
    required String uid,
    required String productId,
    required List<String> localPaths,
  }) async {
    final urls = <String>[];
    for (final path in localPaths) {
      final file = File(path);
      final ext = path.split('.').last.toLowerCase();
      final fileName =
          '$uid/$productId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from(_bucket).upload(
        fileName,
        file,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: false),
      );
      final url = supabase.storage.from(_bucket).getPublicUrl(fileName);
      urls.add(url);
    }
    return urls;
  }

  /// Gửi đánh giá mới lên Supabase, upload ảnh lên Storage nếu có.
  static Future<void> submit(ProductReview review) async {
    final uid = AuthService.currentUserId;
    if (uid == null) throw Exception('Chưa đăng nhập');

    // Upload ảnh nếu có (path local)
    List<String> imageUrls = [];
    final localPaths = review.imagePaths
        .where((p) => !p.startsWith('http'))
        .toList();
    if (localPaths.isNotEmpty) {
      imageUrls = await _uploadImages(
        uid: uid,
        productId: review.productId,
        localPaths: localPaths,
      );
    }

    await supabase.from('reviews').insert({
      'user_id': uid,
      'product_id': review.productId,
      'order_id': review.orderId,
      'rating': review.rating,
      'comment': review.comment,
      'image_urls': imageUrls,
      'created_at': review.createdAt.toIso8601String(),
    });

    // Cập nhật rating qua RPC (Security Definer) để tránh bị RLS block
    await supabase.rpc('update_product_rating', params: {
      'p_product_id': review.productId,
    });
  }

  static ProductReview _rowToReview(Map<String, dynamic> row) {
    final imageUrls =
        (row['image_urls'] as List?)?.map((e) => e as String).toList() ?? [];
    return ProductReview(
      productId: row['product_id'] as String,
      orderId: row['order_id'] as String,
      rating: row['rating'] as int,
      comment: row['comment'] as String,
      imagePaths: imageUrls,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static ProductReview _rowToReviewWithName(Map<String, dynamic> row) {
    final imageUrls =
        (row['image_urls'] as List?)?.map((e) => e as String).toList() ?? [];
    final profile = row['profiles'] as Map<String, dynamic>?;
    return ProductReview(
      productId: row['product_id'] as String,
      orderId: row['order_id'] as String,
      rating: row['rating'] as int,
      comment: row['comment'] as String,
      imagePaths: imageUrls,
      createdAt: DateTime.parse(row['created_at'] as String),
      reviewerName: profile?['name'] as String?,
    );
  }
}
