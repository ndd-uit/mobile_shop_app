import 'dart:async';

import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/customer_profile.dart';
import '../models/product.dart';
import '../models/product_review.dart';
import '../models/shop_order.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/favorite_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/profile_service.dart';
import '../services/review_service.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'change_password_screen.dart';
import 'category_screen.dart';
import 'edit_profile_screen.dart';
import 'home_screen.dart';
import 'favorite_products_screen.dart';
import 'order_history_screen.dart';
import 'shipping_addresses_screen.dart';
import 'settings_screen.dart';

enum _AccountPage {
  root,
  orders,
  editProfile,
  addresses,
  settings,
  favorites,
  changePassword,
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  _AccountPage accountPage = _AccountPage.root;
  final List<CartItem> cartItems = [];
  final List<ShopOrder> orders = [];
  final Set<String> favoriteProductIds = {};
  final List<ProductReview> productReviews = [];
  List<Product> products = const [];
  CustomerProfile customerProfile = const CustomerProfile(
    name: '',
    phoneNumber: '',
  );
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDatabaseData();
  }

  Future<void> _loadDatabaseData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _loading = true);
    }
    try {
      final results = await Future.wait([
        ProductService.fetchAll(),
        ProfileService.fetchCurrent(),
        CartService.fetchAll(),
        OrderService.fetchAll(),
        FavoriteService.fetchIds(),
        ReviewService.fetchByUser(),
      ]);
      if (!mounted) return;
      final dbProducts = results[0] as List<Product>;
      final dbProfile = results[1] as CustomerProfile?;
      final dbCart = results[2] as List<CartItem>;
      final dbOrders = results[3] as List<ShopOrder>;
      final dbFavorites = results[4] as Set<String>;
      final dbReviews = results[5] as List<ProductReview>;

      setState(() {
        products = dbProducts;
        if (dbProfile != null) customerProfile = dbProfile;
        cartItems
          ..clear()
          ..addAll(dbCart);
        orders
          ..clear()
          ..addAll(dbOrders);
        favoriteProductIds
          ..clear()
          ..addAll(dbFavorites);
        productReviews
          ..clear()
          ..addAll(dbReviews);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải dữ liệu. Vui lòng kiểm tra kết nối.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void changeTab(int index) {
    setState(() {
      selectedIndex = index;
      if (index == 3) accountPage = _AccountPage.root;
    });
    if (index == 0 || index == 1) {
      unawaited(_loadDatabaseData(showLoading: false));
    }
  }

  void addToCart(Product product, String size) {
    final currentQuantity = cartItems
        .where((item) => item.id == product.id)
        .fold<int>(0, (total, item) => total + item.quantity);
    if (product.stock <= 0 || currentQuantity >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm đã hết hàng hoặc vượt quá tồn kho'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
    // fire-and-forget — cart lỗi không block UI, nhưng log ra
    CartService.addOrIncrement(product, size).catchError((e) {
      debugPrint('CartService.addOrIncrement error: $e');
    });
  }

  void removeCartItem(String key) {
    final item = cartItems.firstWhere((i) => i.key == key);
    setState(() => cartItems.removeWhere((i) => i.key == key));
    CartService.remove(item.id, item.size ?? '').catchError((e) {
      debugPrint('CartService.remove error: $e');
    });
  }

  void updateCartQuantity(String key, int quantity) {
    if (quantity <= 0) {
      removeCartItem(key);
      return;
    }
    final item = cartItems.firstWhere((item) => item.key == key);
    final product = products.where((product) => product.id == item.id).firstOrNull;
    if (product != null && quantity > product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chỉ còn ${product.stock} sản phẩm trong kho'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      final index = cartItems.indexWhere((item) => item.key == key);
      if (index != -1) {
        final item = cartItems[index];
        item.quantity = quantity;
        CartService.updateQuantity(
          item.id,
          item.size ?? '',
          quantity,
        ).catchError((e) => debugPrint('CartService.updateQuantity: $e'));
      }
    });
  }

  /// Đặt hàng — await DB để đảm bảo dữ liệu được lưu trước khi báo thành công.
  Future<bool> addOrder(ShopOrder order, {bool clearCart = false}) async {
    final stockError = _stockErrorForOrder(order);
    if (stockError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stockError), behavior: SnackBarBehavior.floating),
      );
      return false;
    }
    try {
      await OrderService.create(order);
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt hàng thất bại. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    if (clearCart) {
      try {
        await CartService.clearAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đơn đã được tạo nhưng chưa thể làm trống giỏ hàng.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
    setState(() {
      orders.insert(0, order);
      if (clearCart) cartItems.clear();
    });
    return true;
  }

  String? _stockErrorForOrder(ShopOrder order) {
    final quantities = <String, int>{};
    for (final item in order.items) {
      quantities[item.id] = (quantities[item.id] ?? 0) + item.quantity;
    }
    for (final entry in quantities.entries) {
      final product = products.where((product) => product.id == entry.key).firstOrNull;
      if (product == null) continue;
      if (product.stock <= 0) return '${product.name} đã hết hàng';
      if (entry.value > product.stock) {
        return '${product.name} chỉ còn ${product.stock} sản phẩm';
      }
    }
    return null;
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

  void goToChangePassword() {
    setState(() => accountPage = _AccountPage.changePassword);
  }

  void goToFavorites() {
    setState(() => accountPage = _AccountPage.favorites);
  }

  void toggleFavorite(Product product) {
    final wasFavorite = favoriteProductIds.contains(product.id);
    setState(() {
      if (wasFavorite) {
        favoriteProductIds.remove(product.id);
      } else {
        favoriteProductIds.add(product.id);
      }
    });
    FavoriteService.toggle(
      product.id,
      wasFavorite,
    ).catchError((e) => debugPrint('FavoriteService.toggle: $e'));
  }

  /// Profile + địa chỉ — await DB, rollback UI nếu lỗi.
  Future<void> updateCustomerProfile(CustomerProfile profile) async {
    final previous = customerProfile;
    setState(() => customerProfile = profile);
    try {
      await ProfileService.save(profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => customerProfile = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu thông tin. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Cập nhật trạng thái đơn hàng — await DB.
  Future<void> updateOrder(ShopOrder updatedOrder) async {
    final index = orders.indexWhere((o) => o.id == updatedOrder.id);
    final previous = index != -1 ? orders[index] : null;
    if (index != -1) setState(() => orders[index] = updatedOrder);

    try {
      await OrderService.updateStatus(updatedOrder);
    } catch (e) {
      if (!mounted) return;
      if (previous != null && index != -1) {
        setState(() => orders[index] = previous);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật đơn hàng. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Gửi đánh giá — await DB.
  Future<void> addProductReview(ProductReview review) async {
    try {
      await ReviewService.submit(review);
      setState(() => productReviews.add(review));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể gửi đánh giá. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    if (!mounted) return;
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
          final product = products.firstWhere(
            (p) => p.id == orderItem.id,
              orElse: () => Product(
                id: orderItem.id,
                name: orderItem.name,
                price: orderItem.unitPrice,
                category: '',
                imageUrl: orderItem.imageUrl ?? '',
                description: '',
                rating: 0,
                stock: orderItem.quantity,
              ),
          );
          CartService.addOrIncrement(
            product,
            orderItem.size ?? '',
          ).catchError((e) => debugPrint('reorder addOrIncrement: $e'));
        } else {
          cartItems[index].quantity += orderItem.quantity;
          CartService.updateQuantity(
            orderItem.id,
            orderItem.size ?? '',
            cartItems[index].quantity,
          ).catchError((e) => debugPrint('reorder updateQuantity: $e'));
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : switch (selectedIndex) {
              0 => HomeScreen(
                customerProfile: customerProfile,
                onAddToCart: addToCart,
                onOrderConfirmed: addOrder,
                onGoHome: goHome,
                onViewOrders: goToOrderHistory,
                favoriteProductIds: favoriteProductIds,
                onToggleFavorite: toggleFavorite,
                products: products,
              ),
              1 => CategoryScreen(
                customerProfile: customerProfile,
                onAddToCart: addToCart,
                onOrderConfirmed: addOrder,
                onGoHome: goHome,
                onViewOrders: goToOrderHistory,
                favoriteProductIds: favoriteProductIds,
                onToggleFavorite: toggleFavorite,
                products: products,
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
                _AccountPage.settings => SettingsScreen(
                  onBack: goToAccount,
                  onChangePassword: goToChangePassword,
                ),
                _AccountPage.changePassword => ChangePasswordScreen(
                  onBack: goToSettings,
                ),
                _AccountPage.favorites => FavoriteProductsScreen(
                  products: products
                      .where(
                        (product) => favoriteProductIds.contains(product.id),
                      )
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
