import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shop_app/models/cart_item.dart';
import 'package:mobile_shop_app/models/customer_profile.dart';
import 'package:mobile_shop_app/screens/cart_screen.dart';

void main() {
  testWidgets('cart total only includes selected products', (tester) async {
    final items = [
      CartItem(
        id: 'p01',
        name: 'Sản phẩm 1',
        price: 100000,
        imageUrl: '',
        quantity: 1,
        size: 'M',
      ),
      CartItem(
        id: 'p02',
        name: 'Sản phẩm 2',
        price: 200000,
        imageUrl: '',
        quantity: 1,
        size: 'L',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          customerProfile: const CustomerProfile(name: '', phoneNumber: ''),
          cartItems: items,
          onRemoveItem: (_) {},
          onUpdateQuantity: (_, _) {},
          onOrderConfirmed: (_) async => true,
          onGoHome: () {},
          onViewOrders: () {},
        ),
      ),
    );

    expect(find.text('300.000đ'), findsOneWidget);
    expect(find.text('Thanh toán (2)'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();

    expect(find.text('100.000đ'), findsNWidgets(2));
    expect(find.text('Thanh toán (1)'), findsOneWidget);
  });
}
