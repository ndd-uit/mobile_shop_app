import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/customer_profile.dart';
import '../models/order_item.dart';
import '../models/shop_order.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  final CustomerProfile customerProfile;
  final List<CartItem> cartItems;
  final ValueChanged<String> onRemoveItem;
  final void Function(String key, int quantity) onUpdateQuantity;
  final Future<bool> Function(ShopOrder order) onOrderConfirmed;
  final VoidCallback onGoHome;
  final VoidCallback onViewOrders;

  const CartScreen({
    super.key,
    required this.customerProfile,
    required this.cartItems,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onOrderConfirmed,
    required this.onGoHome,
    required this.onViewOrders,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> selectedKeys = {};
  final Set<String> knownKeys = {};

  List<CartItem> get cartItems => widget.cartItems;
  List<CartItem> get selectedItems =>
      cartItems.where((item) => selectedKeys.contains(item.key)).toList();
  bool get allSelected =>
      cartItems.isNotEmpty && selectedKeys.length == cartItems.length;

  @override
  void initState() {
    super.initState();
    final keys = cartItems.map((item) => item.key);
    knownKeys.addAll(keys);
    selectedKeys.addAll(keys);
  }

  @override
  void didUpdateWidget(covariant CartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentKeys = cartItems.map((item) => item.key).toSet();
    final newKeys = currentKeys.difference(knownKeys);
    selectedKeys
      ..removeWhere((key) => !currentKeys.contains(key))
      ..addAll(newKeys);
    knownKeys
      ..clear()
      ..addAll(currentKeys);
  }

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  int get totalPrice {
    return selectedItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  void _toggleAll(bool? selected) {
    setState(() {
      if (selected == true) {
        selectedKeys.addAll(cartItems.map((item) => item.key));
      } else {
        selectedKeys.clear();
      }
    });
  }

  void _toggleItem(String key, bool? selected) {
    setState(() {
      if (selected == true) {
        selectedKeys.add(key);
      } else {
        selectedKeys.remove(key);
      }
    });
  }

  void _removeItem(String key) {
    setState(() => selectedKeys.remove(key));
    widget.onRemoveItem(key);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xoá khỏi giỏ hàng'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateQuantity(String key, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(key);
      return;
    }
    widget.onUpdateQuantity(key, newQuantity);
  }

  void _checkout() {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một sản phẩm để thanh toán'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          customerProfile: widget.customerProfile,
          onOrderConfirmed: widget.onOrderConfirmed,
          onGoHome: widget.onGoHome,
          onViewOrders: widget.onViewOrders,
          items: selectedItems
              .map(
                (item) => OrderItem(
                  id: item.id,
                  name: item.name,
                  unitPrice: item.price,
                  imageUrl: item.imageUrl,
                  quantity: item.quantity,
                  size: item.size,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: allSelected,
                                onChanged: _toggleAll,
                                activeColor: AppTheme.primary,
                              ),
                              const Expanded(
                                child: Text(
                                  'Chọn tất cả',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${selectedItems.length}/${cartItems.length} sản phẩm',
                                style: const TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Cart items
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cartItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return _buildCartItem(item);
                          },
                        ),

                        const SizedBox(height: 28),

                        // Order summary
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tổng cộng',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    formatPrice(totalPrice),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: selectedItems.isEmpty
                                      ? null
                                      : _checkout,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryContainer,
                                    foregroundColor:
                                        AppTheme.onPrimaryContainer,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Thanh toán (${selectedItems.length})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: selectedKeys.contains(item.key),
            onChanged: (value) => _toggleItem(item.key, value),
            activeColor: AppTheme.primary,
            visualDensity: VisualDensity.compact,
          ),
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 80,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 80,
                  height: 96,
                  color: AppTheme.surface,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppTheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and delete button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                          height: 1.3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      color: AppTheme.outline,
                      hoverColor: AppTheme.error,
                      onPressed: () => _removeItem(item.key),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (item.size != null && item.size!.isNotEmpty) ...[
                  Text(
                    'Size: ${item.size}',
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Price and quantity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatPrice(item.price),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    // Quantity selector
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              icon: const Icon(Icons.remove),
                              iconSize: 16,
                              color: AppTheme.onSurfaceVariant,
                              onPressed: () =>
                                  _updateQuantity(item.key, item.quantity - 1),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(
                            width: 24,
                            child: Center(
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              icon: const Icon(Icons.add),
                              iconSize: 16,
                              color: AppTheme.onSurfaceVariant,
                              onPressed: () =>
                                  _updateQuantity(item.key, item.quantity + 1),
                              padding: EdgeInsets.zero,
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
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppTheme.primaryContainer,
            ),
            const SizedBox(height: 16),
            const Text(
              'Giỏ hàng trống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thêm sản phẩm để tiếp tục mua sắm',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onGoHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Tiếp tục mua sắm'),
            ),
          ],
        ),
      ),
    );
  }
}
