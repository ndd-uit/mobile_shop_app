import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/customer_profile.dart';
import '../models/shop_order.dart';
import '../theme/app_theme.dart';
import '../widgets/size_selection_bottom_sheet.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final CustomerProfile customerProfile;
  final void Function(Product product, String size) onAddToCart;
  final Future<bool> Function(ShopOrder order) onOrderConfirmed;
  final VoidCallback onGoHome;
  final VoidCallback onViewOrders;
  final Set<String> favoriteProductIds;
  final ValueChanged<Product> onToggleFavorite;
  final List<Product> products;

  const HomeScreen({
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primary = Color(0xFF81515B);
  static const Color surface = Color(0xFFFBF9F9);
  static const Color onSurface = Color(0xFF1B1C1C);
  static const Color onSurfaceVariant = Color(0xFF514345);

  String selectedCategory = 'Tất cả';
  String searchQuery = '';

  // Filter & Sort state
  _SortOption _sortOption = _SortOption.newest;
  RangeValues _priceRange = const RangeValues(0, 5000000);
  static const double _maxPrice = 5000000;

  final List<String> categories = const [
    'Tất cả',
    'Váy',
    'Áo',
    'Quần',
    'Phụ kiện',
  ];

  bool get _hasActiveFilter =>
      _priceRange.start > 0 ||
      _priceRange.end < _maxPrice ||
      _sortOption != _SortOption.newest;

  List<Product> get filteredProducts {
    var list = widget.products.where((product) {
      final matchCategory =
          selectedCategory == 'Tất cả' || product.category == selectedCategory;
      final matchSearch = product.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final matchPrice =
          product.price >= _priceRange.start &&
          product.price <= _priceRange.end;
      return matchCategory && matchSearch && matchPrice;
    }).toList();

    switch (_sortOption) {
      case _SortOption.newest:
        break; // giữ thứ tự từ server
      case _SortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case _SortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case _SortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _FilterSheet(
        sortOption: _sortOption,
        priceRange: _priceRange,
        maxPrice: _maxPrice,
        onApply: (sort, price) {
          setState(() {
            _sortOption = sort;
            _priceRange = price;
          });
          Navigator.pop(sheetCtx);
        },
        onReset: () {
          setState(() {
            _sortOption = _SortOption.newest;
            _priceRange = const RangeValues(0, _maxPrice);
          });
          Navigator.pop(sheetCtx);
        },
      ),
    );
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: onSurfaceVariant),
                onPressed: _showFilterSheet,
                tooltip: 'Lọc & Sắp xếp',
              ),
              if (_hasActiveFilter)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
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
            children: [
              Text(
                'Sản phẩm mới',
                style: const TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (products.isNotEmpty)
                Text(
                  '${products.length} sản phẩm',
                  style: const TextStyle(
                    color: onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                  onAddToCart: () {
                    showSizeSelectionBottomSheet(
                      context: context,
                      product: product,
                      onConfirm: (size) => widget.onAddToCart(product, size),
                    );
                  },
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
        separatorBuilder: (_, _) => const SizedBox(width: 10),
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
              errorBuilder: (_, _, _) {
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
  final VoidCallback onAddToCart;

  const _ProductCard({
    required this.product,
    required this.priceText,
    required this.onTap,
    required this.isFavorite,
    required this.onFavorite,
    required this.onAddToCart,
  });

  bool get isNew => product.id == 'p02';
  bool get isDiscount => product.oldPrice != null;

  String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

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
                    errorBuilder: (_, _, _) {
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
                  // ── Quick add button ──
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _CircleIcon(
                      icon: Icons.add_shopping_cart_outlined,
                      onTap: onAddToCart,
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
                Flexible(
                  child: Text(
                    priceText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF81515B),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatPrice(product.oldPrice!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                    color: Color(0xFF837375),
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    ),
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

// ─────────────────────────────────────────────
// Sort & Filter
// ─────────────────────────────────────────────

enum _SortOption { newest, priceAsc, priceDesc, ratingDesc }

class _FilterSheet extends StatefulWidget {
  final _SortOption sortOption;
  final RangeValues priceRange;
  final double maxPrice;
  final void Function(_SortOption, RangeValues) onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.sortOption,
    required this.priceRange,
    required this.maxPrice,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _SortOption _sort;
  late RangeValues _price;

  @override
  void initState() {
    super.initState();
    _sort = widget.sortOption;
    _price = widget.priceRange;
  }

  String _formatPrice(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}tr';
    }
    return '${(value / 1000).round()}k';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lọc & Sắp xếp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onReset,
                  child: const Text(
                    'Đặt lại',
                    style: TextStyle(color: AppTheme.outline),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Sort
            const Text(
              'Sắp xếp theo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SortChip(
                  label: 'Mới nhất',
                  icon: Icons.fiber_new_outlined,
                  selected: _sort == _SortOption.newest,
                  onTap: () => setState(() => _sort = _SortOption.newest),
                ),
                _SortChip(
                  label: 'Giá tăng dần',
                  icon: Icons.arrow_upward,
                  selected: _sort == _SortOption.priceAsc,
                  onTap: () => setState(() => _sort = _SortOption.priceAsc),
                ),
                _SortChip(
                  label: 'Giá giảm dần',
                  icon: Icons.arrow_downward,
                  selected: _sort == _SortOption.priceDesc,
                  onTap: () => setState(() => _sort = _SortOption.priceDesc),
                ),
                _SortChip(
                  label: 'Đánh giá cao',
                  icon: Icons.star_outline,
                  selected: _sort == _SortOption.ratingDesc,
                  onTap: () => setState(() => _sort = _SortOption.ratingDesc),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Price range
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Khoảng giá',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${_formatPrice(_price.start)} – ${_formatPrice(_price.end)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            RangeSlider(
              values: _price,
              min: 0,
              max: widget.maxPrice,
              divisions: 50,
              activeColor: AppTheme.primary,
              inactiveColor: AppTheme.outlineVariant,
              onChanged: (values) => setState(() => _price = values),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0đ',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.outline,
                    ),
                  ),
                  Text(
                    '5.000.000đ',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Apply button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => widget.onApply(_sort, _price),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryContainer : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
