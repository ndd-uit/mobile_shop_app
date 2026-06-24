import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shop_app/models/customer_profile.dart';
import 'package:mobile_shop_app/models/product.dart';
import 'package:mobile_shop_app/screens/favorite_products_screen.dart';

void main() {
  const product = Product(
    id: 'favorite-1',
    name: 'Váy yêu thích',
    price: 450000,
    category: 'Váy',
    imageUrl: '',
    description: 'Sản phẩm thử nghiệm',
    rating: 4.8,
  );

  Widget buildScreen({
    required ValueChanged<Product> onToggleFavorite,
    required void Function(Product, String) onAddToCart,
  }) {
    return MaterialApp(
      home: FavoriteProductsScreen(
        products: const [product],
        favoriteProductIds: const {'favorite-1'},
        onToggleFavorite: onToggleFavorite,
        onAddToCart: onAddToCart,
        customerProfile: const CustomerProfile(name: 'Thảo', phoneNumber: ''),
        onOrderConfirmed: (_) async => true,
        onGoHome: () {},
        onViewOrders: () {},
        onBack: () {},
      ),
    );
  }

  testWidgets('removes a product from favorites', (tester) async {
    Product? removedProduct;
    await tester.pumpWidget(
      buildScreen(
        onToggleFavorite: (value) => removedProduct = value,
        onAddToCart: (_, _) {},
      ),
    );

    await tester.tap(find.byIcon(Icons.favorite));
    expect(removedProduct?.id, product.id);
  });

  testWidgets('adds only selected favorites to cart', (tester) async {
    Product? addedProduct;
    String? addedSize;
    await tester.pumpWidget(
      buildScreen(
        onToggleFavorite: (_) {},
        onAddToCart: (product, size) {
          addedProduct = product;
          addedSize = size;
        },
      ),
    );

    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    await tester.tap(find.text('Thêm 1 sản phẩm vào giỏ'));
    await tester.pump();

    expect(addedProduct?.id, product.id);
    expect(addedSize, 'M');
  });
}
