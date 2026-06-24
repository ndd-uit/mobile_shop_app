import 'package:flutter/material.dart';

import '../models/customer_profile.dart';
import '../models/product.dart';
import '../models/shop_order.dart';
import '../theme/app_theme.dart';
import '../widgets/size_selection_bottom_sheet.dart';
import 'product_detail_screen.dart';

class FavoriteProductsScreen extends StatefulWidget {
  final List<Product> products;
  final Set<String> favoriteProductIds;
  final ValueChanged<Product> onToggleFavorite;
  final void Function(Product product, String size) onAddToCart;
  final CustomerProfile customerProfile;
  final Future<bool> Function(ShopOrder order) onOrderConfirmed;
  final VoidCallback onGoHome;
  final VoidCallback onViewOrders;
  final VoidCallback onBack;

  const FavoriteProductsScreen({
    super.key,
    required this.products,
    required this.favoriteProductIds,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.customerProfile,
    required this.onOrderConfirmed,
    required this.onGoHome,
    required this.onViewOrders,
    required this.onBack,
  });

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen> {
  String selectedCategory = 'Tất cả';
  final Set<String> selectedProductIds = {};

  List<Product> get visibleProducts {
    if (selectedCategory == 'Tất cả') return widget.products;
    return widget.products
        .where((product) => product.category == selectedCategory)
        .toList();
  }

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  Widget _buildCategoryFilters() {
    final categories = <String>{
      'Tất cả',
      ...widget.products.map((product) => product.category),
    }.toList();

    if (categories.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => selectedCategory = category),
            backgroundColor: AppTheme.surfaceContainerLow,
            selectedColor: AppTheme.primaryContainer,
            side: BorderSide(
              color: selected
                  ? AppTheme.primaryContainer
                  : AppTheme.outlineVariant,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? AppTheme.onPrimaryContainer
                  : AppTheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant FavoriteProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.products.map((product) => product.id).toSet();
    selectedProductIds.removeWhere((id) => !currentIds.contains(id));
  }

  bool get allVisibleSelected =>
      visibleProducts.isNotEmpty &&
      visibleProducts.every(
        (product) => selectedProductIds.contains(product.id),
      );

  bool get someVisibleSelected =>
      visibleProducts.any((product) => selectedProductIds.contains(product.id));

  void _toggleAllVisible(bool? selected) {
    setState(() {
      final ids = visibleProducts.map((product) => product.id);
      if (selected == true) {
        selectedProductIds.addAll(ids);
      } else {
        selectedProductIds.removeAll(ids);
      }
    });
  }

  void _toggleProduct(String id, bool? selected) {
    setState(() {
      if (selected == true) {
        selectedProductIds.add(id);
      } else {
        selectedProductIds.remove(id);
      }
    });
  }

  /// Thêm các sản phẩm đã chọn vào giỏ.
  /// Nếu chỉ chọn 1 sản phẩm → hiện bottom sheet chọn size.
  /// Nếu chọn nhiều → thêm với size mặc định 'M'.
  void _addSelectedToCart() {
    final selectedProducts = widget.products
        .where((product) => selectedProductIds.contains(product.id))
        .toList();

    if (selectedProducts.length == 1) {
      final product = selectedProducts.first;
      showSizeSelectionBottomSheet(
        context: context,
        product: product,
        onConfirm: (size) {
          widget.onAddToCart(product, size);
          setState(() => selectedProductIds.clear());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm "${product.name}" (size $size) vào giỏ hàng'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
      return;
    }

    for (final product in selectedProducts) {
      widget.onAddToCart(product, 'M');
    }
    setState(() => selectedProductIds.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã thêm ${selectedProducts.length} sản phẩm vào giỏ hàng',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ProductDetailScreen(
          customerProfile: widget.customerProfile,
          product: product,
          onAddToCart: widget.onAddToCart,
          onOrderConfirmed: widget.onOrderConfirmed,
          onGoHome: widget.onGoHome,
          onViewOrders: widget.onViewOrders,
          isFavorite: widget.favoriteProductIds.contains(product.id),
          onToggleFavorite: widget.onToggleFavorite,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = visibleProducts;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.surface,
        centerTitle: true,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Sản phẩm yêu thích',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: widget.products.isEmpty
          ? _EmptyFavorites(onExplore: widget.onGoHome)
          : Column(
              children: [
                _buildCategoryFilters(),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              Checkbox(
                                tristate: true,
                                value: allVisibleSelected
                                    ? true
                                    : someVisibleSelected
                                    ? null
                                    : false,
                                onChanged: _toggleAllVisible,
                                activeColor: AppTheme.primary,
                              ),
                              const Text(
                                'Chọn tất cả',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                '${selectedProductIds.length} đã chọn',
                                style: const TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (products.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text('Không có sản phẩm trong danh mục này'),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverGrid.builder(
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.64,
                                ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return _FavoriteCard(
                                product: product,
                                price: formatPrice(product.price),
                                selected: selectedProductIds.contains(
                                  product.id,
                                ),
                                onSelected: (value) =>
                                    _toggleProduct(product.id, value),
                                onTap: () => openProduct(product),
                                onRemove: () =>
                                    widget.onToggleFavorite(product),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.products.isNotEmpty)
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      decoration: const BoxDecoration(
                        color: AppTheme.surface,
                        border: Border(
                          top: BorderSide(color: AppTheme.outlineVariant),
                        ),
                      ),
                      child: FilledButton.icon(
                        onPressed: selectedProductIds.isEmpty
                            ? null
                            : _addSelectedToCart,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(
                          'Thêm ${selectedProductIds.length} sản phẩm vào giỏ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Product product;
  final String price;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool selected;
  final ValueChanged<bool?> onSelected;

  const _FavoriteCard({
    required this.product,
    required this.price,
    required this.onTap,
    required this.onRemove,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppTheme.surfaceContainer,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: Checkbox(
                        value: selected,
                        onChanged: onSelected,
                        activeColor: AppTheme.primary,
                        shape: const CircleBorder(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.88),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.favorite),
                        color: AppTheme.primaryContainer,
                        iconSize: 21,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onExplore;

  const _EmptyFavorites({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 72,
              color: AppTheme.primaryContainer,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có sản phẩm yêu thích',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            const Text(
              'Hãy thả tim sản phẩm bạn thích để lưu lại tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onExplore,
              child: const Text('Khám phá sản phẩm'),
            ),
          ],
        ),
      ),
    );
  }
}
