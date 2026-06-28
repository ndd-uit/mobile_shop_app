import 'package:flutter/material.dart';

import '../models/order_item.dart';
import '../models/customer_profile.dart';
import '../models/product.dart';
import '../models/product_review.dart';
import '../models/shop_order.dart';
import '../theme/app_theme.dart';
import '../services/review_service.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final CustomerProfile customerProfile;
  final Product product;
  final void Function(Product product, String size) onAddToCart;
  final Future<bool> Function(ShopOrder order) onOrderConfirmed;
  final VoidCallback onGoHome;
  final VoidCallback onViewOrders;
  final bool isFavorite;
  final ValueChanged<Product> onToggleFavorite;

  const ProductDetailScreen({
    super.key,
    required this.customerProfile,
    required this.product,
    required this.onAddToCart,
    required this.onOrderConfirmed,
    required this.onGoHome,
    required this.onViewOrders,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _SizeChart extends StatelessWidget {
  final String selectedSize;

  const _SizeChart({required this.selectedSize});

  static const rows = [
    ('S', '82-84', '64-66', '88-90'),
    ('M', '86-88', '68-70', '92-94'),
    ('L', '90-92', '72-74', '96-98'),
    ('XL', '94-96', '76-78', '100-102'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const _SizeRow(cells: ['Size', 'Ngực', 'Eo', 'Mông'], isHeader: true),
          for (final row in rows)
            _SizeRow(
              cells: [row.$1, row.$2, row.$3, row.$4],
              isSelected: row.$1 == selectedSize,
            ),
        ],
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  final bool isSelected;

  const _SizeRow({
    required this.cells,
    this.isHeader = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isHeader
            ? AppTheme.primaryContainer.withValues(alpha: 0.18)
            : isSelected
            ? AppTheme.primaryContainer.withValues(alpha: 0.12)
            : AppTheme.surfaceContainerLowest,
        border: isHeader
            ? const Border(bottom: BorderSide(color: AppTheme.outlineVariant))
            : const Border(
                bottom: BorderSide(color: AppTheme.surfaceContainerHighest),
              ),
      ),
      child: Row(
        children: cells.map((cell) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(
                cell,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isHeader ? AppTheme.primary : AppTheme.onSurface,
                  fontSize: 13,
                  fontWeight: isHeader || isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MeasurementTip extends StatelessWidget {
  final String number;
  final String title;
  final String detail;

  const _MeasurementTip({
    required this.number,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: detail,
                    style: const TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int currentImageIndex = 0;
  late String selectedSize;
  late bool isFavorite;
  List<ProductReview> _reviews = [];
  bool _reviewsLoading = true;
  bool _reviewsLoadFailed = false;

  final List<String> sizes = ['S', 'M', 'L', 'XL'];

  List<String> get _productImages {
    final urls = widget.product.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toList();
    if (urls.isNotEmpty) return urls;
    return widget.product.imageUrl.trim().isEmpty
        ? const []
        : [widget.product.imageUrl];
  }

  @override
  void initState() {
    super.initState();
    selectedSize = 'M';
    isFavorite = widget.isFavorite;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _reviewsLoading = true;
      _reviewsLoadFailed = false;
    });
    try {
      final reviews = await ReviewService.fetchByProduct(widget.product.id);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _reviewsLoading = false;
        _reviewsLoadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reviewsLoading = false;
        _reviewsLoadFailed = true;
      });
    }
  }

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showProductImageViewer(List<String> urls, int initial) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ImageViewer(urls: urls, initialIndex: initial),
      ),
    );
  }

  void _showSizeGuide() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Hướng dẫn chọn kích thước',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                      color: AppTheme.outline,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SizeChart(selectedSize: selectedSize),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Số đo được tính bằng cm. Với sản phẩm co giãn cao, bạn có thể chọn lùi 1 size để ôm dáng hơn.',
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Cách đo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const _MeasurementTip(
                          number: '1',
                          title: 'Vòng ngực',
                          detail: 'Đo quanh phần đầy nhất của ngực.',
                        ),
                        const _MeasurementTip(
                          number: '2',
                          title: 'Vòng eo',
                          detail: 'Đo quanh phần eo nhỏ nhất, không siết dây.',
                        ),
                        const _MeasurementTip(
                          number: '3',
                          title: 'Vòng mông',
                          detail: 'Đo quanh phần đầy nhất của hông và mông.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    foregroundColor: AppTheme.onPrimaryContainer,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productImages = _productImages;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Main content with scroll
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: AppTheme.surface.withValues(alpha: 0.8),
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: AppTheme.onSurface,
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Daisy Shop',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
                actions: const [SizedBox(width: 48)],
              ),

              // Product Image Carousel
              SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Container(
                    color: AppTheme.surfaceContainerLow,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (productImages.isEmpty)
                          const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          )
                        else
                          PageView.builder(
                            itemCount: productImages.length,
                            onPageChanged: (index) {
                              setState(() => currentImageIndex = index);
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _showProductImageViewer(
                                  productImages,
                                  index,
                                ),
                                child: Image.network(
                                  productImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) {
                                    return Container(
                                      color: AppTheme.surfaceContainerLow,
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 64,
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        // Carousel indicators
                        if (productImages.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                productImages.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == currentImageIndex
                                        ? AppTheme.primary
                                        : AppTheme.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Details container
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Price Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatPrice(widget.product.price),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppTheme.primary
                                  : AppTheme.outline,
                            ),
                            onPressed: () {
                              setState(() => isFavorite = !isFavorite);
                              widget.onToggleFavorite(widget.product);
                              _showSnackBar(
                                isFavorite
                                    ? 'Đã thêm vào yêu thích'
                                    : 'Đã xóa khỏi yêu thích',
                              );
                            },
                          ),
                        ],
                      ),

                      // Rating
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            if (_reviewsLoading) ...[
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Đang tải...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ] else if (_reviewsLoadFailed) ...[
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: AppTheme.outline,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Không tải được đánh giá',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ] else if (_reviews.isEmpty) ...[
                              const Icon(
                                Icons.star_border,
                                size: 16,
                                color: AppTheme.outline,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Chưa có đánh giá',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ] else ...[
                              _StarRow(
                                rating: _reviews.fold(0.0, (s, r) => s + r.rating) /
                                    _reviews.length,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${(_reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length).toStringAsFixed(1)} (${_reviews.length} đánh giá)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Size Selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kích thước',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showSizeGuide,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.straighten, size: 17),
                                label: const Text(
                                  'Hướng dẫn chọn size',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(sizes.length, (index) {
                              final size = sizes[index];
                              final isSelected = size == selectedSize;

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedSize = size;
                                    });
                                  },
                                  child: Container(
                                    height: 48,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryContainer
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.outlineVariant,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Center(
                                      child: Text(
                                        size,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? AppTheme.onPrimaryContainer
                                              : AppTheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Description Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chi tiết sản phẩm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDescriptionContent(),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Reviews Section ──
                      _buildReviewsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng cộng',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatPrice(widget.product.price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  widget.onAddToCart(
                                    widget.product,
                                    selectedSize,
                                  );
                                  _showSnackBar(
                                    'Đã thêm ${widget.product.name} vào giỏ hàng',
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  side: const BorderSide(
                                    color: AppTheme.primary,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text('Thêm vào giỏ'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutScreen(
                                        customerProfile: widget.customerProfile,
                                        onOrderConfirmed:
                                            widget.onOrderConfirmed,
                                        onGoHome: widget.onGoHome,
                                        onViewOrders: widget.onViewOrders,
                                        items: [
                                          OrderItem(
                                            id: widget.product.id,
                                            name: widget.product.name,
                                            unitPrice: widget.product.price,
                                            imageUrl: widget.product.imageUrl,
                                            quantity: 1,
                                            size: selectedSize,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text('Mua ngay'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8, top: 2),
            child: Text(
              '•',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionContent() {
    final description = widget.product.description.trim();
    if (description.isEmpty) {
      return const Text(
        'Sản phẩm chưa có mô tả chi tiết.',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.onSurfaceVariant,
          height: 1.5,
        ),
      );
    }

    final lines = description
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length <= 1) {
      return Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppTheme.onSurfaceVariant,
          height: 1.5,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          _buildBulletPoint(
            line.replaceFirst(RegExp(r'^[-•]\s*'), ''),
          ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final avgRating = _reviews.isEmpty
        ? 0.0
        : _reviews.fold(0.0, (sum, r) => sum + r.rating) / _reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          children: [
            const Expanded(
              child: Text(
                'Đánh giá sản phẩm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            if (_reviews.isNotEmpty)
              Row(
                children: [
                  _StarRow(rating: avgRating, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    ' (${_reviews.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Content ──
        if (_reviewsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_reviewsLoadFailed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 44,
                  color: AppTheme.outlineVariant,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Không thể tải đánh giá',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kiểm tra kết nối hoặc quyền đọc review trên Supabase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.outline,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loadReviews,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 44,
                  color: AppTheme.outlineVariant,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Chưa có đánh giá nào',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hãy là người đầu tiên đánh giá sản phẩm này!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _reviews.take(5).map((review) {
              return _ReviewCard(review: review);
            }).toList(),
          ),

        // ── Rating summary bar ──
        if (_reviews.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RatingSummaryBar(reviews: _reviews),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Star row widget (fill / half / empty)
// ─────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;

  const _StarRow({required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i + 1;
        IconData icon;
        if (rating >= full) {
          icon = Icons.star;
        } else if (rating >= full - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: size, color: AppTheme.primary);
      }),
    );
  }
}

// ─────────────────────────────────────────────
// Review widgets
// ─────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ProductReview review;

  const _ReviewCard({required this.review});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()} năm trước';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} tháng trước';
    if (diff.inDays >= 1) return '${diff.inDays} ngày trước';
    if (diff.inHours >= 1) return '${diff.inHours} giờ trước';
    return 'Vừa xong';
  }

  void _showImageFullscreen(BuildContext context, List<String> urls, int initial) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ImageViewer(urls: urls, initialIndex: initial),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  (review.reviewerName?.isNotEmpty == true)
                      ? review.reviewerName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName ?? 'Người dùng ẩn danh',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      _timeAgo(review.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              _StarRow(rating: review.rating.toDouble(), size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          // ── Review images ──
          if (review.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imagePaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final url = review.imagePaths[i];
                  return GestureDetector(
                    onTap: () => _showImageFullscreen(context, review.imagePaths, i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 80,
                          height: 80,
                          color: AppTheme.surfaceContainerLow,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppTheme.outline,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingSummaryBar extends StatelessWidget {
  final List<ProductReview> reviews;

  const _RatingSummaryBar({required this.reviews});

  @override
  Widget build(BuildContext context) {
    // Count per star level
    final counts = List.generate(5, (i) {
      return reviews.where((r) => r.rating == 5 - i).length;
    });
    final total = reviews.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(5, (i) {
          final star = 5 - i;
          final count = counts[i];
          final fraction = total == 0 ? 0.0 : count / total;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  child: Text(
                    '$star',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 12, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: AppTheme.outlineVariant,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primaryContainer),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Fullscreen image viewer
// ─────────────────────────────────────────────

class _ImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _ImageViewer({required this.urls, required this.initialIndex});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
