import 'package:flutter/material.dart';

import '../data/mock_products.dart';
import '../models/product.dart';
import '../models/customer_profile.dart';
import '../models/shop_order.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final CustomerProfile customerProfile;
  final void Function(Product product, String size) onAddToCart;
  final ValueChanged<ShopOrder> onOrderConfirmed;
  final VoidCallback onGoHome;
  final VoidCallback onViewOrders;
  final Set<String> favoriteProductIds;
  final ValueChanged<Product> onToggleFavorite;

  const HomeScreen({
    super.key,
    required this.customerProfile,
    required this.onAddToCart,
    required this.onOrderConfirmed,
    required this.onGoHome,
    required this.onViewOrders,
    required this.favoriteProductIds,
    required this.onToggleFavorite,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primary = Color(0xFF81515B);
  static const Color surface = Color(0xFFFBF9F9);
  static const Color onSurface = Color(0xFF1B1C1C);
  static const Color onSurfaceVariant = Color(0xFF514345);

  String selectedCategory = 'Tất cả';
  String searchQuery = '';

  final List<String> categories = const [
    'Tất cả',
    'Váy',
    'Áo',
    'Quần',
    'Phụ kiện',
  ];

  List<Product> get filteredProducts {
    return mockProducts.where((product) {
      final matchCategory =
          selectedCategory == 'Tất cả' || product.category == selectedCategory;

      final matchSearch = product.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      return matchCategory && matchSearch;
    }).toList();
  }

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  @override
  Widget build(BuildContext context) {
    final products = filteredProducts;

    return Scaffold(
      backgroundColor: surface,
      drawer: _HomeDrawer(
        onSelectCategory: (category) {
          setState(() => selectedCategory = category);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: onSurfaceVariant),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Daisy Shop',
          style: TextStyle(
            color: primary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          SizedBox(width: 40), // Spacer for center alignment
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        children: [
          _SearchBox(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 24),
          _CategoryChips(
            categories: categories,
            selectedCategory: selectedCategory,
            onSelected: (category) {
              setState(() {
                selectedCategory = category;
              });
            },
          ),
          const SizedBox(height: 24),
          _HeroBanner(
            onShopNow: () => setState(() => selectedCategory = 'Váy'),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Sản phẩm mới',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Xem thêm',
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const _NoResult()
          else
            GridView.builder(
              itemCount: products.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 12,
                childAspectRatio: 0.54,
              ),
              itemBuilder: (context, index) {
                final product = products[index];

                return _ProductCard(
                  product: product,
                  priceText: formatPrice(product.price),
                  isFavorite: widget.favoriteProductIds.contains(product.id),
                  onFavorite: () => widget.onToggleFavorite(product),
                  onTap: () {
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
                          isFavorite: widget.favoriteProductIds.contains(
                            product.id,
                          ),
                          onToggleFavorite: widget.onToggleFavorite,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm sản phẩm...',
        hintStyle: const TextStyle(color: Color(0xFF514345), fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF514345)),
        filled: true,
        fillColor: const Color(0xFFF5F3F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryContainer
                    : AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: AppTheme.onPrimaryContainer,
                    ),
                  if (isSelected) const SizedBox(width: 6),
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.onPrimaryContainer
                          : AppTheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final VoidCallback onShopNow;

  const _HeroBanner({required this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCKAVi9ZkVAUyLNKxtS_f4Qd9fiiJqO5vqMr9lbS-oEwj0Y0m4BcM5PpzfuHoBH_jsuXz7ixgOEkf1ykWznIS-rQsdBVuAZFJVzlGhlLFEzxkJsC4aYGrgiGVGxFibNESgW6TJ0yVqQKF3QKzsuOmmDwhlmwFO1ZpOfywLbf9v1-aLMbDSbEgogBJhf3ndKr6dO_UO--ZT6SSHj7D0-iJ_NAtyLxxnjF5dziuNbMhQhh81yzni_VQtj_9u9dTlHDN5jBVnZOJSISSs',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD6A1AA), Color(0xFFFACBD5)],
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF81515B).withValues(alpha: 0.80),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Mùa hè rực rỡ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Giảm giá lên đến 50% cho bộ sưu tập mới.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onShopNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC1CC),
                      foregroundColor: const Color(0xFF7B4C56),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Mua ngay',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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

class _ProductCard extends StatelessWidget {
  final Product product;
  final String priceText;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const _ProductCard({
    required this.product,
    required this.priceText,
    required this.onTap,
    required this.isFavorite,
    required this.onFavorite,
  });

  bool get isNew => product.id == 'p02';
  bool get isDiscount => product.id == 'p04';
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
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: const Color(0xFFF5F3F3),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF837375),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _CircleIcon(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      onTap: onFavorite,
                    ),
                  ),
                  if (isNew)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: _Badge(
                        text: 'NEW',
                        backgroundColor: Color(0xFFFFC1CC),
                        textColor: Color(0xFF7B4C56),
                      ),
                    ),
                  if (isDiscount)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: _Badge(
                        text: '-15%',
                        backgroundColor: Color(0xFFFFDAD6),
                        textColor: Color(0xFF93000A),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1B1C1C),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          if (isDiscount)
            Row(
              children: [
                Text(
                  priceText,
                  style: const TextStyle(
                    color: Color(0xFF81515B),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '450.000đ',
                  style: TextStyle(
                    color: Color(0xFF837375),
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            )
          else
            Text(
              priceText,
              style: const TextStyle(
                color: Color(0xFF81515B),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: const Color(0xFF81515B), size: 20),
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final ValueChanged<String> onSelectCategory;

  const _HomeDrawer({required this.onSelectCategory});

  @override
  Widget build(BuildContext context) {
    void showMessage(String label) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label đang được cập nhật'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.8,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 22),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(color: AppTheme.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Daisy Shop',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chào bạn!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DrawerItem(
                    icon: Icons.new_releases_outlined,
                    label: 'Sản phẩm mới',
                    onTap: () => onSelectCategory('Tất cả'),
                  ),
                  _DrawerItem(
                    icon: Icons.category_outlined,
                    label: 'Bộ sưu tập',
                    onTap: () => onSelectCategory('Váy'),
                  ),
                  _DrawerItem(
                    icon: Icons.local_offer_outlined,
                    label: 'Khuyến mãi',
                    onTap: () => showMessage('Khuyến mãi'),
                  ),
                  _DrawerItem(
                    icon: Icons.article_outlined,
                    label: 'Tin tức',
                    onTap: () => showMessage('Tin tức'),
                  ),
                  _DrawerItem(
                    icon: Icons.call_outlined,
                    label: 'Liên hệ',
                    onTap: () => showMessage('Liên hệ'),
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.onSurfaceVariant),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      shape: const StadiumBorder(),
      onTap: onTap,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _Badge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.search_off, size: 52, color: Color(0xFFFFC1CC)),
          SizedBox(height: 12),
          Text(
            'Không tìm thấy sản phẩm',
            style: TextStyle(
              color: Color(0xFF1B1C1C),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Thử tìm kiếm bằng từ khóa khác',
            style: TextStyle(color: Color(0xFF514345), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
