import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/order_item.dart';
import '../models/product_review.dart';
import '../theme/app_theme.dart';

class WriteReviewScreen extends StatefulWidget {
  final String orderId;
  final OrderItem item;
  final ValueChanged<ProductReview> onSubmitted;

  const WriteReviewScreen({
    super.key,
    required this.orderId,
    required this.item,
    required this.onSubmitted,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final reviewController = TextEditingController();
  final imagePicker = ImagePicker();
  final List<String> imagePaths = [];
  int rating = 0;
  bool submitting = false;

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  Future<void> pickImages() async {
    final remaining = 3 - imagePaths.length;
    if (remaining <= 0) return;

    final images = await imagePicker.pickMultiImage(
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (!mounted || images.isEmpty) return;
    setState(() {
      imagePaths.addAll(images.take(remaining).map((image) => image.path));
    });
  }

  Future<void> submitReview() async {
    FocusScope.of(context).unfocus();
    final comment = reviewController.text.trim();
    if (rating == 0) {
      showMessage('Vui lòng chọn số sao đánh giá');
      return;
    }
    if (comment.length < 10) {
      showMessage('Nội dung đánh giá cần ít nhất 10 ký tự');
      return;
    }

    setState(() => submitting = true);
    widget.onSubmitted(
      ProductReview(
        productId: widget.item.id,
        orderId: widget.orderId,
        rating: rating,
        comment: comment,
        imagePaths: List.unmodifiable(imagePaths),
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() => submitting = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppTheme.primary, size: 52),
        title: const Text('Cảm ơn bạn!'),
        content: const Text(
          'Đánh giá của bạn đã được gửi thành công.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Viết đánh giá',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
        children: [
          _ProductSummary(
            item: widget.item,
            price: formatPrice(widget.item.unitPrice),
          ),
          const SizedBox(height: 28),
          const Text(
            'Bạn đánh giá sản phẩm thế nào?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => setState(() => rating = value),
                icon: Icon(
                  value <= rating ? Icons.star : Icons.star_border,
                  color: value <= rating
                      ? AppTheme.primaryContainer
                      : AppTheme.outlineVariant,
                  size: 38,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            rating == 0 ? 'Chạm để chọn số sao' : _ratingLabel(rating),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          const Text(
            'Chia sẻ trải nghiệm của bạn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reviewController,
            minLines: 6,
            maxLines: 8,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText:
                  'Chia sẻ cảm nhận về chất lượng vải, đường may và form dáng nhé...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hình ảnh thực tế',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${imagePaths.length}/3',
                style: const TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (imagePaths.length < 3) _AddPhotoButton(onTap: pickImages),
                for (final path in imagePaths) ...[
                  const SizedBox(width: 10),
                  _SelectedImage(
                    path: path,
                    onRemove: () => setState(() => imagePaths.remove(path)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
          ),
          child: FilledButton.icon(
            onPressed: submitting ? null : submitReview,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: AppTheme.onPrimaryContainer,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text(
              'Gửi đánh giá',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int value) => switch (value) {
    1 => 'Rất không hài lòng',
    2 => 'Chưa hài lòng',
    3 => 'Bình thường',
    4 => 'Hài lòng',
    _ => 'Rất hài lòng',
  };
}

class _ProductSummary extends StatelessWidget {
  final OrderItem item;
  final String price;

  const _ProductSummary({required this.item, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.imageUrl ?? '',
              width: 76,
              height: 92,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 76,
                height: 92,
                color: AppTheme.surfaceContainer,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Phân loại: Size ${item.size ?? 'Freesize'}',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.outlineVariant, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppTheme.outline),
            SizedBox(height: 5),
            Text(
              'Thêm ảnh',
              style: TextStyle(color: AppTheme.outline, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedImage extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _SelectedImage({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 84,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: -5,
          top: -5,
          child: Material(
            color: AppTheme.error,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: Icon(Icons.close, color: Colors.white, size: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
