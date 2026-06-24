import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/customer_profile.dart';
import '../models/shop_order.dart';
import '../theme/app_theme.dart';
import '../widgets/size_selection_bottom_sheet.dart';
import 'product_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final CustomerProfile customerProfile;
  final void Function(Product product, String size) onAddToCart;
  final Future<bool> Function(ShopOrder order) onOrderConfirmed;
  final VoidCallback onGoHome;
  final VoidCallback onViewOrders;
  final Set<String> favoriteProductIds;
  final ValueChanged<Product> onToggleFavorite;
  final List<Product> products;

  const CategoryScreen({
    super.key,
    required this.customerProfile,
    required this.onAddToCart,
    required this.onOrderConfirmed,
    required this.onGoHome,
    required this.onViewOrders,
    required this.favoriteProductIds,
    required this.onToggleFavorite,
    required this.products,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final searchController = TextEditingController();
  final categories = const ['Váy', 'Áo', 'Quần', 'Phụ kiện', 'Giày dép'];
  String selectedCategory = 'Váy';
  String searchQuery = '';

  static const subcategoryNames = <String, List<String>>{
    'Váy': ['Váy Midi', 'Váy Maxi', 'Váy Mini', 'Váy Dạ Hội'],
    'Áo': ['Áo Sơ Mi', 'Áo Kiểu', 'Áo Thun', 'Áo Khoác'],
    'Quần': ['Quần Short', 'Quần Dài', 'Quần Jeans', 'Quần Culottes'],
    'Phụ kiện': ['Dây Chuyền', 'Túi Xách', 'Khuyên Tai', 'Khăn Lụa'],
    'Giày dép': ['Giày Cao Gót', 'Giày Búp Bê', 'Sandal', 'Giày Thể Thao'],
  };

  static const dressImages = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDwdtwhgXWuzhiO7JtDV9d7EisGC0_uVTa8qsOmZygl6ojog_N7qVnrjBsm1otBEPVhBuYEm7_7e9ik5xe4wZcgTqC5PXW-FaFD1bHsFf7W3RNW7vmdSnGvUciWoVmdefTMxbh5dkNWT2dUxBs6QTWlcgGgX7RotcsSDAFJ6WOje0Hz4_WNFDhzYnaBSFsAU3VJU3H1TJGTKxyU4pmmi8hMW9r_1BI1HeXKZjxcwON9N0JaGuA-wIxkZCZQJssO3NZ7ICV0R9mszzU',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBjT-S43aVfPeYANZBfo5xjIY8KpONZSHHAwpfv4XAP6vQ-4DrmfxbPrs3xDWtdN3ukiVRpOnlgBWSICmnyIHJSDqcaBWrkZOENA1apIOV_sVF5BkAS7NmKFdZiquMdqVpu6KWP_lsSw73e73eavqyglwf4rBAUAZTJawNiVidZD4D_g0LzttKgxjbjYPx8R8J7I11Z06hy4_hnXfDrcsJgLvS8QZ9mXAxxDYHohc6z2-dStZMiu213ZK44N9thmInztK34XATQXvM',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAnElDPim361t58p4MVXmjgRR1k407Kkv2KXt3CkGmzu51ZA7YLfwc9i9dBPnwLCieOdUKCX3xZ0w-5NJMpgAdsOj3rbZ56KE8_EhXV7xT_x2Jglls5YUpax8ksewGyVfSZdhKZCtyletLlYnx-b0hhjwkIPLmwh0CaES8uujShYhAnNvlcClSnT8pB4M6YOxiPdDHqknsUX1GfCi2E7jlZA2z3DATqHddLZwhrqAoOYXxtuxWzJB_3hthd7rldWjT7sIaglnJoJD0',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBW0iKy4343jPf1xXVXswrbmWpe7fskMMH4BnboIOeV5LK9a_J4WEcQ0tHFTi37rf2C1qjNKUueKARxRpQwCnyZBe_mWuCdDtzyHn6-bnxp0xdX_Bg_la2Bz2X2OHvTEFXyC61oiJeGZQilGwnpZ0yx_SEG_BPm1RtVeRXSf7_CvlE01fQ4jkwyfRuE4mybsNEt_XFhdgnM2ztwj8pen5here0p-ijLZj6jFTDByVDoP1JNafN-4vq6andFoLsx1aUF9CW5RNScMsQ',
  ];

  List<Product> get searchResults {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
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

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.surface,
        centerTitle: true,
        title: const Text(
          'Daisy Shop',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          TextField(
            controller: searchController,
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.secondary),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() => searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildCategoryChips(),
          const SizedBox(height: 20),
          if (searchQuery.trim().isNotEmpty)
            _buildSearchResults()
          else
            _buildSubcategories(),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => selectedCategory = category),
            backgroundColor: AppTheme.surfaceContainerLow,
            selectedColor: AppTheme.primaryContainer,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            labelStyle: TextStyle(
              color: selected
                  ? AppTheme.onPrimaryContainer
                  : AppTheme.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubcategories() {
    final names = subcategoryNames[selectedCategory] ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh mục $selectedCategory',
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: names.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final image = selectedCategory == 'Váy'
                ? dressImages[index]
                : widget.products.isEmpty
                ? ''
                : widget.products[index % widget.products.length].imageUrl;
            return _SubcategoryCard(
              name: names[index],
              imageUrl: image,
              onTap: () {
                final products = widget.products
                    .where((product) => product.category == selectedCategory)
                    .toList();
                if (products.isNotEmpty) {
                  openProduct(products.first);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${names[index]} đang được cập nhật'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final products = searchResults;
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 56, color: AppTheme.primaryContainer),
            SizedBox(height: 12),
            Text(
              'Không tìm thấy sản phẩm',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${products.length} kết quả',
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.67,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return _SearchProductCard(
              product: product,
              price: formatPrice(product.price),
              onTap: () => openProduct(product),
              onAddToCart: () {
                showSizeSelectionBottomSheet(
                  context: context,
                  product: product,
                  onConfirm: (size) => widget.onAddToCart(product, size),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _SubcategoryCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppTheme.surfaceContainerLow,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppTheme.outline,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppTheme.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchProductCard extends StatelessWidget {
  final Product product;
  final String price;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _SearchProductCard({
    required this.product,
    required this.price,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppTheme.surfaceContainerLow,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onAddToCart,
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.add_shopping_cart_outlined,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
