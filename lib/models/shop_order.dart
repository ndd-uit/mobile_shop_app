import 'order_item.dart';

enum OrderStatus { delivering, completed, cancelled, returnRequested, returned }

class ShopOrder {
  final String id;
  final DateTime orderedAt;
  final OrderStatus status;
  final List<OrderItem> items;
  final int shippingFee;
  final String customerName;
  final String phoneNumber;
  final String shippingAddress;
  final String paymentMethod;
  final int discount;
  final String? voucherCode;
  final String? cancellationReason;
  final String? returnReason;
  final DateTime? statusUpdatedAt;

  const ShopOrder({
    required this.id,
    required this.orderedAt,
    required this.status,
    required this.items,
    this.shippingFee = 30000,
    this.customerName = 'Nguyễn Thu Thảo',
    this.phoneNumber = '0901234567',
    this.shippingAddress = '123 Đường Lê Lợi, Quận 1, TP. HCM',
    this.paymentMethod = 'Thanh toán khi nhận hàng (COD)',
    this.discount = 0,
    this.voucherCode,
    this.cancellationReason,
    this.returnReason,
    this.statusUpdatedAt,
  });

  int get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  int get totalPrice => subtotal + shippingFee - discount;

  ShopOrder copyWith({
    OrderStatus? status,
    String? cancellationReason,
    String? returnReason,
    DateTime? statusUpdatedAt,
  }) {
    return ShopOrder(
      id: id,
      orderedAt: orderedAt,
      status: status ?? this.status,
      items: items,
      shippingFee: shippingFee,
      customerName: customerName,
      phoneNumber: phoneNumber,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      discount: discount,
      voucherCode: voucherCode,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      returnReason: returnReason ?? this.returnReason,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
    );
  }
}
