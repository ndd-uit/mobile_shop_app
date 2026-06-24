import 'package:flutter/material.dart';

import '../models/order_item.dart';
import '../models/shop_order.dart';
import '../models/product_review.dart';
import '../theme/app_theme.dart';
import '../widgets/order_action_dialog.dart';
import 'write_review_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final ShopOrder order;
  final ValueChanged<ShopOrder> onReorder;
  final ValueChanged<ShopOrder>? onOrderUpdated;
  final List<ProductReview> reviews;
  final Future<void> Function(ProductReview)? onReviewSubmitted;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.onReorder,
    this.onOrderUpdated,
    this.reviews = const [],
    this.onReviewSubmitted,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

enum _TrackingState { completed, current, pending, error }

class _TrackingData {
  final String title;
  final String? detail;
  final _TrackingState state;

  const _TrackingData({
    required this.title,
    required this.detail,
    required this.state,
  });
}

class _TrackingStep extends StatelessWidget {
  final _TrackingData data;
  final bool isLast;

  const _TrackingStep({required this.data, required this.isLast});

  bool get isCompleted => data.state == _TrackingState.completed;
  bool get isCurrent => data.state == _TrackingState.current;
  bool get isError => data.state == _TrackingState.error;

  Color get color {
    if (isError) return AppTheme.error;
    if (isCompleted || isCurrent) return AppTheme.primary;
    return AppTheme.outlineVariant;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCompleted || isError
                        ? color
                        : isCurrent
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: AppTheme.primary, width: 2)
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 15)
                      : isError
                      ? const Icon(Icons.close, color: Colors.white, size: 15)
                      : Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.primary
                                : AppTheme.outlineVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? AppTheme.primary
                          : AppTheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: isCurrent
                          ? AppTheme.primary
                          : isError
                          ? AppTheme.error
                          : data.state == _TrackingState.pending
                          ? AppTheme.onSurfaceVariant
                          : AppTheme.onSurface,
                      fontSize: 13,
                      fontWeight: isCurrent || isError
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  if (data.detail != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      data.detail!,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late ShopOrder order = widget.order;

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  String formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
  }

  String statusLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.delivering => 'Đang giao',
      OrderStatus.completed => 'Đã hoàn thành',
      OrderStatus.cancelled => 'Đã hủy',
      OrderStatus.returnRequested => 'Đang hoàn hàng',
      OrderStatus.returned => 'Đã hoàn hàng',
    };
  }

  IconData statusIcon(OrderStatus status) {
    return switch (status) {
      OrderStatus.delivering => Icons.local_shipping,
      OrderStatus.completed => Icons.check_circle,
      OrderStatus.cancelled => Icons.cancel,
      OrderStatus.returnRequested => Icons.assignment_return_outlined,
      OrderStatus.returned => Icons.assignment_turned_in_outlined,
    };
  }

  Color statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.delivering => AppTheme.onPrimaryContainer,
      OrderStatus.completed => AppTheme.secondary,
      OrderStatus.cancelled => AppTheme.onErrorContainer,
      OrderStatus.returnRequested => const Color(0xFF6D4500),
      OrderStatus.returned => AppTheme.secondary,
    };
  }

  Color statusBackground(OrderStatus status) {
    return switch (status) {
      OrderStatus.delivering => AppTheme.primaryContainer,
      OrderStatus.completed => AppTheme.surfaceContainer,
      OrderStatus.cancelled => AppTheme.errorContainer,
      OrderStatus.returnRequested => const Color(0xFFFFDEA5),
      OrderStatus.returned => AppTheme.surfaceContainer,
    };
  }

  void reorder(BuildContext context) {
    widget.onReorder(order);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> performAction(OrderAction action) async {
    final updated = await showOrderActionDialog(
      context,
      order: order,
      action: action,
    );
    if (updated == null || !mounted) return;
    setState(() => order = updated);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.onSurfaceVariant,
        ),
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildTrackingCard(),
          if (order.cancellationReason != null ||
              order.returnReason != null) ...[
            const SizedBox(height: 16),
            _buildRequestReasonCard(),
          ],
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.location_on_outlined,
            title: 'Địa chỉ nhận hàng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.customerName}  |  ${order.phoneNumber}',
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  order.shippingAddress,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.payments_outlined,
            title: 'Phương thức thanh toán',
            child: Text(
              order.paymentMethod,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildProductsCard(),
          const SizedBox(height: 16),
          _buildPaymentDetails(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.secondaryContainer)),
          ),
          child: _buildActions(context),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đơn hàng #${order.id}',
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatDate(order.orderedAt),
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBackground(order.status),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon(order.status),
                  size: 16,
                  color: statusColor(order.status),
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel(order.status),
                  style: TextStyle(
                    color: statusColor(order.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard() {
    final steps = _trackingSteps();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trạng thái đơn hàng',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < steps.length; index++)
            _TrackingStep(
              data: steps[index],
              isLast: index == steps.length - 1,
            ),
          if (order.status == OrderStatus.delivering) ...[
            const Divider(height: 24),
            Text(
              'Dự kiến giao hàng: ${formatDate(order.orderedAt.add(const Duration(days: 3)))}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_TrackingData> _trackingSteps() {
    final ordered = order.orderedAt;
    final prepared = ordered.add(const Duration(hours: 2));
    final shipped = ordered.add(const Duration(days: 1));
    final delivered = ordered.add(const Duration(days: 3));
    final updated = order.statusUpdatedAt ?? delivered;

    if (order.status == OrderStatus.cancelled) {
      return [
        _TrackingData(
          title: 'Đã đặt hàng',
          detail: formatDateTime(ordered),
          state: _TrackingState.completed,
        ),
        _TrackingData(
          title: 'Đã hủy đơn',
          detail: formatDateTime(updated),
          state: _TrackingState.error,
        ),
      ];
    }

    final deliverySteps = <_TrackingData>[
      _TrackingData(
        title: 'Chờ xác nhận',
        detail: formatDateTime(ordered),
        state: _TrackingState.completed,
      ),
      _TrackingData(
        title: 'Đang chuẩn bị',
        detail: formatDateTime(prepared),
        state: _TrackingState.completed,
      ),
      _TrackingData(
        title: 'Đang vận chuyển',
        detail: order.status == OrderStatus.delivering
            ? 'Đơn hàng đang trên đường giao đến bạn'
            : formatDateTime(shipped),
        state: order.status == OrderStatus.delivering
            ? _TrackingState.current
            : _TrackingState.completed,
      ),
      _TrackingData(
        title: 'Đã giao',
        detail: order.status == OrderStatus.delivering
            ? null
            : formatDateTime(delivered),
        state: order.status == OrderStatus.delivering
            ? _TrackingState.pending
            : _TrackingState.completed,
      ),
    ];

    if (order.status == OrderStatus.returnRequested) {
      deliverySteps.add(
        _TrackingData(
          title: 'Đang xử lý hoàn hàng',
          detail: formatDateTime(updated),
          state: _TrackingState.current,
        ),
      );
    } else if (order.status == OrderStatus.returned) {
      deliverySteps.addAll([
        _TrackingData(
          title: 'Yêu cầu hoàn hàng',
          detail: formatDateTime(updated.subtract(const Duration(days: 1))),
          state: _TrackingState.completed,
        ),
        _TrackingData(
          title: 'Đã hoàn hàng',
          detail: formatDateTime(updated),
          state: _TrackingState.completed,
        ),
      ]);
    }
    return deliverySteps;
  }

  String formatDateTime(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.hour)}:${twoDigits(date.minute)} - ${formatDate(date)}';
  }

  Widget _buildRequestReasonCard() {
    final isCancellation = order.cancellationReason != null;
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCancellation
                ? Icons.cancel_outlined
                : Icons.assignment_return_outlined,
            color: isCancellation ? AppTheme.error : AppTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCancellation ? 'Lý do hủy đơn' : 'Lý do hoàn hàng',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  order.cancellationReason ?? order.returnReason!,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (order.statusUpdatedAt != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Cập nhật: ${formatDate(order.statusUpdatedAt!)}',
                    style: const TextStyle(
                      color: AppTheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryContainer,
      foregroundColor: AppTheme.onPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    if (order.status == OrderStatus.delivering) {
      return SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: () => performAction(OrderAction.cancel),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.error,
            side: const BorderSide(color: AppTheme.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Hủy đơn'),
        ),
      );
    }

    if (order.status == OrderStatus.completed) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => performAction(OrderAction.requestReturn),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Hoàn hàng'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => reorder(context),
                style: buttonStyle,
                child: const Text('Mua lại'),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () => reorder(context),
        style: buttonStyle,
        child: const Text('Mua lại'),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.only(left: 28), child: child),
        ],
      ),
    );
  }

  Widget _buildProductsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sản phẩm',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < order.items.length; index++) ...[
            if (index > 0) Divider(color: AppTheme.surfaceContainerHighest),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildProduct(order.items[index]),
            ),
            if (_canReview(order.items[index]))
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _writeReview(order.items[index]),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Viết đánh giá'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildProduct(OrderItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.imageUrl ?? '',
            width: 80,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 80,
              height: 96,
              color: AppTheme.surfaceContainerLow,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppTheme.outline,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 96,
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
                  'Phân loại: Size ${item.size ?? 'Freesize'}',
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatPrice(item.unitPrice),
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _canReview(OrderItem item) {
    final delivered =
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.returned;
    final reviewed = widget.reviews.any(
      (review) => review.orderId == order.id && review.productId == item.id,
    );
    return delivered && !reviewed && widget.onReviewSubmitted != null;
  }

  Future<void> _writeReview(OrderItem item) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => WriteReviewScreen(
          orderId: order.id,
          item: item,
          onSubmitted: widget.onReviewSubmitted!,
        ),
      ),
    );
    if (submitted == true && mounted) setState(() {});
  }

  Widget _buildPaymentDetails() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _priceRow('Tạm tính', order.subtotal),
          const SizedBox(height: 8),
          _priceRow('Phí vận chuyển', order.shippingFee),
          if (order.discount > 0) ...[
            const SizedBox(height: 8),
            _priceRow(
              'Giảm giá${order.voucherCode != null ? ' (${order.voucherCode})' : ''}',
              -order.discount,
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppTheme.secondaryContainer),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng cộng',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatPrice(order.totalPrice),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, int value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          formatPrice(value),
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.secondaryContainer),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
