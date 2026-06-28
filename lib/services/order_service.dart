import 'supabase_client.dart';
import '../models/order_item.dart';
import '../models/shop_order.dart';
import 'auth_service.dart';

class OrderService {
  /// Lấy tất cả đơn hàng của user hiện tại kèm order_items.
  static Future<List<ShopOrder>> fetchAll() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return [];

    final rows = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', uid)
        .order('ordered_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToOrder)
        .toList();
  }

  /// Admin: lấy toàn bộ đơn hàng kèm order_items.
  static Future<List<ShopOrder>> fetchAdminAll() async {
    final rows = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .order('ordered_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(_rowToOrder)
        .toList();
  }

  /// Admin: lấy một đơn hàng theo id kèm order_items.
  static Future<ShopOrder?> fetchAdminById(String id) async {
    final row = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return _rowToOrder(row);
  }

  /// Tạo đơn hàng + order_items trong một batch.
  /// Supabase không hỗ trợ client-side transaction nên insert theo thứ tự:
  /// nếu insert items thất bại, xóa order để tránh orphan.
  static Future<void> create(ShopOrder order) async {
    final uid = AuthService.currentUserId;
    if (uid == null) throw Exception('Chưa đăng nhập');

    final subtotal = order.items.fold<int>(0, (s, i) => s + i.totalPrice);

    // 1. Insert order trước
    await supabase.from('orders').insert({
      'id': order.id,
      'user_id': uid,
      'status': _statusToString(order.status),
      'customer_name': order.customerName,
      'phone_number': order.phoneNumber,
      'shipping_address': order.shippingAddress,
      'payment_method': order.paymentMethod,
      'subtotal': subtotal,
      'shipping_fee': order.shippingFee,
      'discount': order.discount,
      if (order.voucherCode != null) 'voucher_code': order.voucherCode,
      'ordered_at': order.orderedAt.toIso8601String(),
    });

    // 2. Insert items — nếu lỗi thì rollback order
    if (order.items.isNotEmpty) {
      try {
        await supabase.from('order_items').insert(
          order.items
              .map((item) => {
                    'order_id': order.id,
                    'product_id': item.id,
                    'product_name': item.name,
                    'unit_price': item.unitPrice,
                  'quantity': item.quantity,
                  'image_url': item.imageUrl,
                  'size': item.size,
                  if (item.color != null) 'color': item.color,
                  if (item.style != null) 'style': item.style,
                })
              .toList(),
        );
      } catch (e) {
        // Rollback: xóa order vừa tạo
        await supabase.from('orders').delete().eq('id', order.id);
        rethrow;
      }
    }
  }

  /// Cập nhật trạng thái đơn hàng (hủy / hoàn hàng).
  static Future<void> updateStatus(ShopOrder order) async {
    await supabase.from('orders').update({
      'status': _statusToString(order.status),
      'cancellation_reason': order.cancellationReason,
      'return_reason': order.returnReason,
      'status_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', order.id);
  }

  /// Admin: cập nhật nhanh trạng thái đơn hàng theo id.
  static Future<void> updateAdminStatus({
    required String id,
    required OrderStatus status,
  }) async {
    await supabase.from('orders').update({
      'status': _statusToString(status),
      'status_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  static ShopOrder _rowToOrder(Map<String, dynamic> row) {
    final itemRows = (row['order_items'] as List)
        .cast<Map<String, dynamic>>();
    final items = itemRows
        .map((r) => OrderItem(
              id: r['product_id'] as String? ?? '',
              name: r['product_name'] as String,
              unitPrice: r['unit_price'] as int,
              quantity: r['quantity'] as int,
              imageUrl: r['image_url'] as String?,
              size: r['size'] as String?,
              color: r['color'] as String?,
              style: r['style'] as String?,
            ))
        .toList();

    return ShopOrder(
      id: row['id'] as String,
      orderedAt: DateTime.parse(row['ordered_at'] as String),
      status: _statusFromString(row['status'] as String),
      items: items,
      shippingFee: row['shipping_fee'] as int,
      customerName: row['customer_name'] as String,
      phoneNumber: row['phone_number'] as String,
      shippingAddress: row['shipping_address'] as String,
      paymentMethod: row['payment_method'] as String,
      discount: row['discount'] as int,
      voucherCode: row['voucher_code'] as String?,
      cancellationReason: row['cancellation_reason'] as String?,
      returnReason: row['return_reason'] as String?,
      statusUpdatedAt: row['status_updated_at'] != null
          ? DateTime.parse(row['status_updated_at'] as String)
          : null,
    );
  }

  static String _statusToString(OrderStatus status) => switch (status) {
        OrderStatus.pendingPayment => 'pending_payment',
        OrderStatus.pendingConfirmation => 'pending_confirmation',
        OrderStatus.preparing => 'preparing',
        OrderStatus.delivering => 'delivering',
        OrderStatus.completed => 'completed',
        OrderStatus.cancelled => 'cancelled',
        OrderStatus.returnRequested => 'return_requested',
        OrderStatus.returned => 'returned',
      };

  static OrderStatus _statusFromString(String s) => switch (s) {
        'pending_payment' => OrderStatus.pendingPayment,
        'pending_confirmation' => OrderStatus.pendingConfirmation,
        'preparing' => OrderStatus.preparing,
        'delivering' => OrderStatus.delivering,
        'completed' => OrderStatus.completed,
        'cancelled' => OrderStatus.cancelled,
        'return_requested' => OrderStatus.returnRequested,
        'returned' => OrderStatus.returned,
        _ => OrderStatus.delivering,
      };
}
