import 'package:flutter/material.dart';

import '../models/order_item.dart';
import '../models/shop_order.dart';
import '../models/product_review.dart';
import '../theme/app_theme.dart';
import '../widgets/order_action_dialog.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final List<ShopOrder> orders;
  final ValueChanged<ShopOrder> onReorder;
  final ValueChanged<ShopOrder>? onOrderUpdated;
  final List<ProductReview> reviews;
  final Future<void> Function(ProductReview)? onReviewSubmitted;
  final VoidCallback? onBack;

  const OrderHistoryScreen({
    super.key,
    required this.orders,
    required this.onReorder,
    this.onOrderUpdated,
    this.reviews = const [],
    this.onReviewSubmitted,
    this.onBack,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  OrderStatus? selectedStatus;

  List<ShopOrder> get filteredOrders {
    if (selectedStatus == null) return widget.orders;
    return widget.orders
        .where((order) => order.status == selectedStatus)
        .toList();
  }

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} ₫';
  }

  String formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
  }

  String statusLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.pendingPayment => 'Chờ thanh toán',
      OrderStatus.pendingConfirmation => 'Chờ xác nhận',
      OrderStatus.preparing => 'Đang chuẩn bị',
      OrderStatus.delivering => 'Đang giao',
      OrderStatus.completed => 'Đã hoàn thành',
      OrderStatus.cancelled => 'Đã hủy',
      OrderStatus.returnRequested => 'Đang hoàn hàng',
      OrderStatus.returned => 'Đã hoàn hàng',
    };
  }

  IconData statusIcon(OrderStatus status) {
    return switch (status) {
      OrderStatus.pendingPayment => Icons.payments_outlined,
      OrderStatus.pendingConfirmation => Icons.schedule,
      OrderStatus.preparing => Icons.inventory_2_outlined,
      OrderStatus.delivering => Icons.local_shipping,
      OrderStatus.completed => Icons.check_circle,
      OrderStatus.cancelled => Icons.cancel,
      OrderStatus.returnRequested => Icons.assignment_return_outlined,
      OrderStatus.returned => Icons.assignment_turned_in_outlined,
    };
  }

  Color statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pendingPayment => const Color(0xFF8A5A00),
      OrderStatus.pendingConfirmation => AppTheme.primary,
      OrderStatus.preparing => AppTheme.primary,
      OrderStatus.delivering => AppTheme.primary,
      OrderStatus.completed => AppTheme.secondary,
      OrderStatus.cancelled => AppTheme.error,
      OrderStatus.returnRequested => const Color(0xFF8A5A00),
      OrderStatus.returned => AppTheme.secondary,
    };
  }

  Color statusBackground(OrderStatus status) {
    return switch (status) {
      OrderStatus.pendingPayment => const Color(0xFFFFDEA5),
      OrderStatus.pendingConfirmation => AppTheme.primaryContainer,
      OrderStatus.preparing => AppTheme.primaryContainer,
      OrderStatus.delivering => AppTheme.primaryContainer,
      OrderStatus.completed => AppTheme.surfaceContainer,
      OrderStatus.cancelled => AppTheme.errorContainer,
      OrderStatus.returnRequested => const Color(0xFFFFDEA5),
      OrderStatus.returned => AppTheme.surfaceContainer,
    };
  }

  void reorder(ShopOrder order) {
    widget.onReorder(order);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm các sản phẩm vào giỏ hàng'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = filteredOrders;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.surface,
        centerTitle: true,
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                color: AppTheme.onSurfaceVariant,
              ),
        title: const Text(
          'Lịch sử đơn hàng',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: orders.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildOrderCard(orders[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = <(String, OrderStatus?)>[
      ('Tất cả', null),
      ('Chờ thanh toán', OrderStatus.pendingPayment),
      ('Chờ xác nhận', OrderStatus.pendingConfirmation),
      ('Chuẩn bị', OrderStatus.preparing),
      ('Đang giao', OrderStatus.delivering),
      ('Đã hoàn thành', OrderStatus.completed),
      ('Đã hủy', OrderStatus.cancelled),
      ('Đang hoàn', OrderStatus.returnRequested),
      ('Đã hoàn', OrderStatus.returned),
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, status) = filters[index];
          final selected = selectedStatus == status;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => selectedStatus = status),
            backgroundColor: AppTheme.surfaceContainerLow,
            selectedColor: AppTheme.primaryContainer,
            side: BorderSide(
              color: selected
                  ? AppTheme.primaryContainer
                  : AppTheme.outlineVariant,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? AppTheme.onPrimaryContainer
                  : AppTheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(ShopOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: AppTheme.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mã đơn hàng: #${order.id}',
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppTheme.surfaceContainerHighest),
          for (var index = 0; index < order.items.length; index++) ...[
            if (index > 0)
              Divider(height: 1, color: AppTheme.surfaceContainerHighest),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildOrderItem(order.items[index]),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ngày đặt: ${formatDate(order.orderedAt)}',
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              const Text(
                'Tổng tiền: ',
                style: TextStyle(color: AppTheme.onSurface, fontSize: 13),
              ),
              Text(
                formatPrice(order.totalPrice),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.outlineVariant),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _showOrderDetails(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurface,
                    side: const BorderSide(color: AppTheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Xem chi tiết'),
                ),
                if (order.status == OrderStatus.pendingPayment ||
                    order.status == OrderStatus.pendingConfirmation ||
                    order.status == OrderStatus.preparing ||
                    order.status == OrderStatus.delivering) ...[
                  OutlinedButton(
                    onPressed: () => _performAction(order, OrderAction.cancel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Hủy đơn'),
                  ),
                  if (order.status == OrderStatus.delivering)
                    FilledButton(
                      onPressed: () => _markAsCompleted(order),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryContainer,
                        foregroundColor: AppTheme.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Đã nhận hàng'),
                    ),
                ],
                if (order.status == OrderStatus.completed) ...[
                  OutlinedButton(
                    onPressed: () =>
                        _performAction(order, OrderAction.requestReturn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Hoàn hàng'),
                  ),
                  ElevatedButton(
                    onPressed: () => reorder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Mua lại'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: statusBackground(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 13, color: statusColor(status)),
          const SizedBox(width: 4),
          Text(
            statusLabel(status),
            style: TextStyle(
              color: statusColor(status),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.imageUrl ?? '',
            width: 64,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 64,
              height: 80,
              color: AppTheme.surfaceContainerLow,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppTheme.outline,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Phân loại: ${item.size ?? 'Freesize'}',
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                'x${item.quantity}',
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatPrice(item.totalPrice),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: AppTheme.primaryContainer,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa có đơn hàng nào',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selectedStatus == null
                  ? 'Các đơn hàng của bạn sẽ xuất hiện tại đây.'
                  : 'Không có đơn hàng ở trạng thái này.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrderDetails(ShopOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          order: order,
          onReorder: widget.onReorder,
          onOrderUpdated: widget.onOrderUpdated,
          reviews: widget.reviews,
          onReviewSubmitted: widget.onReviewSubmitted,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _performAction(ShopOrder order, OrderAction action) async {
    final updated = await showOrderActionDialog(
      context,
      order: order,
      action: action,
    );
    if (updated == null || !mounted) return;
    widget.onOrderUpdated?.call(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == OrderAction.cancel
              ? 'Đã hủy đơn hàng #${order.id}'
              : 'Đã gửi yêu cầu hoàn hàng #${order.id}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAsCompleted(ShopOrder order) {
    final updated = order.copyWith(
      status: OrderStatus.completed,
      statusUpdatedAt: DateTime.now(),
    );
    widget.onOrderUpdated?.call(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đơn hàng #${order.id} đã hoàn thành'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
