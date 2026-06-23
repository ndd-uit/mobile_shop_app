import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shop_app/models/order_item.dart';
import 'package:mobile_shop_app/models/shop_order.dart';
import 'package:mobile_shop_app/screens/order_history_screen.dart';

void main() {
  testWidgets('cancels a delivering order with a selected reason', (
    tester,
  ) async {
    ShopOrder? updatedOrder;
    final order = ShopOrder(
      id: 'TEST01',
      orderedAt: DateTime(2026, 6, 23),
      status: OrderStatus.delivering,
      items: const [
        OrderItem(
          id: 'p01',
          name: 'Váy thử nghiệm',
          unitPrice: 350000,
          quantity: 1,
          size: 'M',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrderHistoryScreen(
          orders: [order],
          onReorder: (_) {},
          onOrderUpdated: (value) => updatedOrder = value,
        ),
      ),
    );

    await tester.tap(find.text('Hủy đơn'));
    await tester.pumpAndSettle();
    expect(find.text('Hủy đơn hàng?'), findsOneWidget);

    await tester.tap(find.text('Đặt nhầm đơn hàng'));
    await tester.pump();
    await tester.tap(find.text('Xác nhận hủy'));
    await tester.pumpAndSettle();

    expect(updatedOrder?.status, OrderStatus.cancelled);
    expect(updatedOrder?.cancellationReason, 'Đặt nhầm đơn hàng');
    expect(updatedOrder?.statusUpdatedAt, isNotNull);
  });
}
