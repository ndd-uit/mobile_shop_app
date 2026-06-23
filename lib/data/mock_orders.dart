import '../models/order_item.dart';
import '../models/shop_order.dart';
import 'mock_products.dart';

List<ShopOrder> createMockOrders() {
  return [
    ShopOrder(
      id: 'DS8921',
      orderedAt: DateTime(2024, 5, 12),
      status: OrderStatus.delivering,
      shippingFee: 0,
      items: [
        OrderItem(
          id: mockProducts[0].id,
          name: mockProducts[0].name,
          unitPrice: mockProducts[0].price,
          imageUrl: mockProducts[0].imageUrl,
          quantity: 1,
          size: 'M',
        ),
      ],
    ),
    ShopOrder(
      id: 'DS8750',
      orderedAt: DateTime(2024, 5, 5),
      status: OrderStatus.completed,
      items: [
        OrderItem(
          id: mockProducts[1].id,
          name: mockProducts[1].name,
          unitPrice: mockProducts[1].price,
          imageUrl: mockProducts[1].imageUrl,
          quantity: 1,
          size: 'M',
        ),
        OrderItem(
          id: mockProducts[2].id,
          name: mockProducts[2].name,
          unitPrice: mockProducts[2].price,
          imageUrl: mockProducts[2].imageUrl,
          quantity: 1,
          size: 'Freesize',
        ),
      ],
    ),
  ];
}
