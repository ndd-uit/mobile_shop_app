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
    for (var i = 0; i < localPaths.length; i++) {
      final path = localPaths[i];
      final file = File(path);
      final ext = _extensionOf(path);
      final fileName =
          '$uid/$productId/${DateTime.now().microsecondsSinceEpoch}_$i.$ext';
      await supabase.storage.from(_bucket).upload(
        fileName,
        file,
        fileOptions: FileOptions(contentType: _contentType(ext), upsert: false),
      );
      final url = supabase.storage.from(_bucket).getPublicUrl(fileName);
      urls.add(url);
    }
    return urls;
  }

  static String _extensionOf(String path) {
    final rawExt = path.split('.').last.toLowerCase();
    return switch (rawExt) {
      'jpeg' || 'jpg' => 'jpg',
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
  }

  static String _contentType(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
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
      try {
        imageUrls = await _uploadImages(
          uid: uid,
          productId: review.productId,
          localPaths: localPaths,
        );
      } catch (_) {
        throw Exception(
          'Không thể tải ảnh đánh giá. Vui lòng kiểm tra bucket $_bucket trên Supabase.',
        );
      }
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

    // Cập nhật rating là dữ liệu phụ. Nếu RPC chưa được deploy/permission lỗi,
    // review vẫn phải được gửi thành công để không tạo cảm giác mất bài đánh giá.
    try {
      await supabase.rpc('update_product_rating', params: {
        'p_product_id': review.productId,
      });
    } catch (_) {
      // Rating trung bình có thể được cập nhật lại sau khi chạy schema.sql.
    }
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
