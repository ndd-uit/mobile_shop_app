import 'package:flutter/material.dart';

import '../data/mock_orders.dart';
import '../data/mock_products.dart';
import '../models/cart_item.dart';
import '../models/customer_profile.dart';
import '../models/product.dart';
import '../models/product_review.dart';
import '../models/shop_order.dart';
import '../theme/app_theme.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'category_screen.dart';
import 'edit_profile_screen.dart';
import 'home_screen.dart';
import 'favorite_products_screen.dart';
import 'order_history_screen.dart';
import 'shipping_addresses_screen.dart';
import 'settings_screen.dart';

enum _AccountPage { root, orders, editProfile, addresses, settings, favorites }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  _AccountPage accountPage = _AccountPage.root;
  final List<CartItem> cartItems = [];
  final List<ShopOrder> orders = createMockOrders();
  final Set<String> favoriteProductIds = {};
  final List<ProductReview> productReviews = [];
  CustomerProfile customerProfile = const CustomerProfile(
    name: 'Nguyễn Thu Thảo',
    phoneNumber: '0901234567',
  );

  void changeTab(int index) {
    setState(() {
      selectedIndex = index;
      if (index == 3) accountPage = _AccountPage.root;
    });
  }

  void addToCart(Product product, String size) {
    setState(() {
      final index = cartItems.indexWhere(
        (item) => item.id == product.id && item.size == size,
      );

      if (index == -1) {
        cartItems.add(
          CartItem(
            id: product.id,
            name: product.name,
            price: product.price,
            imageUrl: product.imageUrl,
            quantity: 1,
            size: size,
          ),
        );
      } else {
        cartItems[index].quantity++;
      }
    });
  }

  void removeCartItem(String key) {
    setState(() {
      cartItems.removeWhere((item) => item.key == key);
    });
  }

  void updateCartQuantity(String key, int quantity) {
    if (quantity <= 0) {
      removeCartItem(key);
      return;
    }

    setState(() {
      final index = cartItems.indexWhere((item) => item.key == key);
      if (index != -1) {
        cartItems[index].quantity = quantity;
      }
    });
  }

  void addOrder(ShopOrder order, {bool clearCart = false}) {
    setState(() {
      orders.insert(0, order);
      if (clearCart) cartItems.clear();
    });
  }

  void goHome() => setState(() => selectedIndex = 0);

  void goToOrderHistory() => setState(() {
    selectedIndex = 3;
    accountPage = _AccountPage.orders;
  });

  void goToAccount() => setState(() => accountPage = _AccountPage.root);

  void goToEditProfile() {
    setState(() => accountPage = _AccountPage.editProfile);
  }

  void goToShippingAddresses() {
    setState(() => accountPage = _AccountPage.addresses);
  }

  void goToSettings() {
    setState(() => accountPage = _AccountPage.settings);
  }

  void goToFavorites() {
    setState(() => accountPage = _AccountPage.favorites);
  }

  void toggleFavorite(Product product) {
    setState(() {
      if (!favoriteProductIds.add(product.id)) {
        favoriteProductIds.remove(product.id);
      }
    });
  }

  void updateCustomerProfile(CustomerProfile profile) {
    setState(() => customerProfile = profile);
  }

  void updateOrder(ShopOrder updatedOrder) {
    setState(() {
      final index = orders.indexWhere((order) => order.id == updatedOrder.id);
      if (index != -1) orders[index] = updatedOrder;
    });
  }

  void addProductReview(ProductReview review) {
    setState(() => productReviews.add(review));
  }

  void logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  void reorder(ShopOrder order) {
    setState(() {
      for (final orderItem in order.items) {
        final index = cartItems.indexWhere(
          (item) => item.id == orderItem.id && item.size == orderItem.size,
        );
        if (index == -1) {
          cartItems.add(
            CartItem(
              id: orderItem.id,
              name: orderItem.name,
              price: orderItem.unitPrice,
              imageUrl: orderItem.imageUrl ?? '',
              quantity: orderItem.quantity,
              size: orderItem.size,
            ),
          );
        } else {
          cartItems[index].quantity += orderItem.quantity;
        }
      }
      selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = cartItems.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    return Scaffold(
      body: switch (selectedIndex) {
        0 => HomeScreen(
          customerProfile: customerProfile,
          onAddToCart: addToCart,
          onOrderConfirmed: addOrder,
          onGoHome: goHome,
          onViewOrders: goToOrderHistory,
          favoriteProductIds: favoriteProductIds,
          onToggleFavorite: toggleFavorite,
        ),
        1 => CategoryScreen(
          customerProfile: customerProfile,
          onAddToCart: addToCart,
          onOrderConfirmed: addOrder,
          onGoHome: goHome,
          onViewOrders: goToOrderHistory,
          favoriteProductIds: favoriteProductIds,
          onToggleFavorite: toggleFavorite,
        ),
        2 => CartScreen(
          customerProfile: customerProfile,
          cartItems: cartItems,
          onRemoveItem: removeCartItem,
          onUpdateQuantity: updateCartQuantity,
          onOrderConfirmed: (order) => addOrder(order, clearCart: true),
          onGoHome: goHome,
          onViewOrders: goToOrderHistory,
        ),
        _ => switch (accountPage) {
          _AccountPage.orders => OrderHistoryScreen(
            orders: orders,
            onReorder: reorder,
            onOrderUpdated: updateOrder,
            reviews: productReviews,
            onReviewSubmitted: addProductReview,
            onBack: goToAccount,
          ),
          _AccountPage.editProfile => EditProfileScreen(
            profile: customerProfile,
            onProfileChanged: updateCustomerProfile,
            onBack: goToAccount,
          ),
          _AccountPage.addresses => ShippingAddressesScreen(
            profile: customerProfile,
            onProfileChanged: updateCustomerProfile,
            onBack: goToAccount,
          ),
          _AccountPage.settings => SettingsScreen(onBack: goToAccount),
          _AccountPage.favorites => FavoriteProductsScreen(
            products: mockProducts
                .where((product) => favoriteProductIds.contains(product.id))
                .toList(),
            favoriteProductIds: favoriteProductIds,
            onToggleFavorite: toggleFavorite,
            onAddToCart: addToCart,
            customerProfile: customerProfile,
            onOrderConfirmed: addOrder,
            onGoHome: goHome,
            onViewOrders: goToOrderHistory,
            onBack: goToAccount,
          ),
          _ => AccountScreen(
            profile: customerProfile,
            onProfileChanged: updateCustomerProfile,
            onViewOrders: goToOrderHistory,
            onEditProfile: goToEditProfile,
            onManageAddresses: goToShippingAddresses,
            onOpenSettings: goToSettings,
            onViewFavorites: goToFavorites,
            onLogout: logout,
          ),
        },
      },
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: changeTab,
          backgroundColor: AppTheme.surface,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Danh mục',
            ),
            BottomNavigationBarItem(
              icon: _CartNavigationIcon(
                count: cartItemCount,
                icon: Icons.shopping_cart_outlined,
              ),
              activeIcon: _CartNavigationIcon(
                count: cartItemCount,
                icon: Icons.shopping_cart,
              ),
              label: 'Giỏ hàng',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}

class _CartNavigationIcon extends StatelessWidget {
  final int count;
  final IconData icon;

  const _CartNavigationIcon({required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            top: -7,
            right: -10,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Daisy Shop',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 20))),
    );
  }
}
