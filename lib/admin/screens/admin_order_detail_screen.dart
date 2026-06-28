import 'package:flutter/material.dart';

import '../../models/order_item.dart';
import '../../models/shop_order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/admin_feedback.dart';
import '../widgets/admin_shell.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  String selectedStatus = 'Đang giao hàng';
  Future<ShopOrder?>? orderFuture;
  String? orderId;
  String? statusSyncedOrderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (orderFuture != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is Map ? args['id'] as String? : null;
    orderId = id;
    orderFuture = id == null
        ? Future<ShopOrder?>.value(null)
        : OrderService.fetchAdminById(id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopOrder?>(
      future: orderFuture,
      builder: (context, snapshot) {
        final order = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminShell(
            currentSection: AdminSection.orders,
            showSearch: false,
            child: AdminStatePanel.loading(),
          );
        }
        if (snapshot.hasError) {
          return AdminShell(
            currentSection: AdminSection.orders,
            showSearch: false,
            child: AdminStatePanel.error(onAction: _refreshOrder),
          );
        }
        if (order == null) {
          return AdminShell(
            currentSection: AdminSection.orders,
            showSearch: false,
            child: AdminStatePanel.empty(
              title: 'Không tìm thấy đơn hàng',
              message: 'Đơn hàng không tồn tại hoặc bạn chưa có quyền xem.',
              actionLabel: 'Quay lại danh sách',
              onAction: () => Navigator.pushReplacementNamed(
                context,
                '/admin/orders',
              ),
            ),
          );
        }

        if (statusSyncedOrderId != order.id) {
          selectedStatus = _statusLabel(order.status);
          statusSyncedOrderId = order.id;
        }
        final products = order.items.map(_OrderProduct.fromItem).toList();

        return AdminShell(
          currentSection: AdminSection.orders,
          showSearch: false,
          breadcrumb: _OrderDetailBreadcrumb(orderId: order.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          _DetailHeader(order: order),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 980;
              final cards = [
                _CustomerCard(order: order),
                _ShippingCard(order: order),
                _PaymentCard(order: order),
              ];
              if (!desktop) {
                return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      if (card != cards.last) const SizedBox(height: 16),
                    ],
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _CustomerCard(order: order)),
                    const SizedBox(width: 16),
                    Expanded(child: _ShippingCard(order: order)),
                    const SizedBox(width: 16),
                    Expanded(child: _PaymentCard(order: order)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 980;
              if (!desktop) {
                return Column(
                  children: [
                    _ProductListCard(products: products, order: order),
                    const SizedBox(height: 16),
                    _StatusUpdateCard(
                      selectedStatus: selectedStatus,
                      onChanged: (value) => setState(() => selectedStatus = value),
                      onSave: () => _saveStatus(order),
                    ),
                    const SizedBox(height: 16),
                    _TimelineCard(order: order),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _ProductListCard(products: products, order: order),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _StatusUpdateCard(
                          selectedStatus: selectedStatus,
                          onChanged: (value) => setState(() => selectedStatus = value),
                          onSave: () => _saveStatus(order),
                        ),
                        const SizedBox(height: 24),
                        _TimelineCard(order: order),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
        );
      },
    );
  }

  void _refreshOrder() {
    setState(() {
      orderFuture = orderId == null
          ? Future<ShopOrder?>.value(null)
          : OrderService.fetchAdminById(orderId!);
    });
  }

  Future<void> _saveStatus(ShopOrder order) async {
    try {
      await OrderService.updateAdminStatus(
        id: order.id,
        status: _statusFromLabel(selectedStatus),
      );
      if (!mounted) return;
      _refreshOrder();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu trạng thái đơn hàng'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được trạng thái: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _OrderDetailBreadcrumb extends StatelessWidget {
  final String orderId;

  const _OrderDetailBreadcrumb({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin/orders'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Danh sách đơn hàng'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.onSurfaceVariant),
        ),
        const Text('/', style: TextStyle(color: AppTheme.outlineVariant)),
        const SizedBox(width: 8),
        Text(
          _displayOrderId(orderId),
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final ShopOrder order;

  const _DetailHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết đơn hàng ${_displayOrderId(order.id)}',
              style: const TextStyle(fontSize: 24, height: 1.25, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Đặt lúc: ${_formatDateTime(order.orderedAt)}',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusPill(label: _statusLabel(order.status)),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: actions),
            ],
          );
        }
        return Row(children: [Expanded(child: title), actions]);
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_outlined, color: AppTheme.onPrimaryContainer, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


class _CustomerCard extends StatelessWidget {
  final ShopOrder order;

  const _CustomerCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.person_outline,
      iconColor: AppTheme.primary,
      iconBackground: AppTheme.primaryFixed,
      title: 'Thông tin khách hàng',
      subtitle: 'Thành viên thân thiết',
      child: Column(
        children: [
          _InfoRow(label: 'Họ và tên:', value: order.customerName),
          const SizedBox(height: 16),
          _InfoRow(label: 'Số điện thoại:', value: order.phoneNumber),
        ],
      ),
    );
  }
}

class _ShippingCard extends StatelessWidget {
  final ShopOrder order;

  const _ShippingCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.location_on_outlined,
      iconColor: AppTheme.secondary,
      iconBackground: AppTheme.secondaryContainer,
      title: 'Địa chỉ giao hàng',
      subtitle: 'Giao hàng tiêu chuẩn',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            order.shippingAddress,
            style: const TextStyle(color: AppTheme.onSurfaceVariant, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final ShopOrder order;

  const _PaymentCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppTheme.tertiary,
      iconBackground: AppTheme.tertiaryContainer,
      title: 'Thanh toán',
      subtitleWidget: _PaidBadge(paid: _isPaid(order)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        'Tạo lúc ${_formatDateTime(order.orderedAt)}',
                        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _InfoRow(label: 'Tổng tiền:', value: _formatMoney(order.totalPrice), valueSize: 18),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    subtitleWidget ??
                        Text(
                          subtitle ?? '',
                          style: const TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double valueSize;

  const _InfoRow({required this.label, required this.value, this.valueSize = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PaidBadge extends StatelessWidget {
  final bool paid;

  const _PaidBadge({required this.paid});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: paid ? const Color(0xFFE6F4EA) : AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          paid ? 'Đã thanh toán' : 'Chưa thanh toán',
          style: TextStyle(
            color: paid ? const Color(0xFF137333) : AppTheme.onErrorContainer,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  final List<_OrderProduct> products;
  final ShopOrder order;

  const _ProductListCard({required this.products, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách sản phẩm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${products.length} Sản phẩm',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 680) {
                return Column(
                  children: [
                    for (final product in products) _MobileProductRow(product: product),
                  ],
                );
              }
              return Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(0.95),
                  2: FlexColumnWidth(0.72),
                  3: FlexColumnWidth(1.0),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: AppTheme.surfaceContainerLow),
                    children: [
                      _TableHeader('Sản phẩm'),
                      _TableHeader('Giá'),
                      _TableHeader('SL'),
                      _TableHeader('Tổng', alignRight: true),
                    ],
                  ),
                  for (final product in products) _productRow(product),
                ],
              );
            },
          ),
          _OrderTotals(order: order),
        ],
      ),
    );
  }

  TableRow _productRow(_OrderProduct product) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _ProductImage(url: product.imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      product.variant,
                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ProductTableCell(product.price),
        _ProductTableCell(product.quantity),
        _ProductTableCell(product.total, alignRight: true, bold: true),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _TableHeader(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductTableCell extends StatelessWidget {
  final String text;
  final bool alignRight;
  final bool bold;

  const _ProductTableCell(this.text, {this.alignRight = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
      ),
    );
  }
}

class _MobileProductRow extends StatelessWidget {
  final _OrderProduct product;

  const _MobileProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(url: product.imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  product.variant,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text('${product.quantity} x ${product.price}'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(product.total, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String url;

  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 64,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 64,
          height: 80,
          color: AppTheme.surfaceContainer,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      ),
    );
  }
}

class _OrderTotals extends StatelessWidget {
  final ShopOrder order;

  const _OrderTotals({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withValues(alpha: 0.6),
        border: const Border(top: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            children: [
              _TotalRow(label: 'Tạm tính:', value: _formatMoney(order.subtotal)),
              const SizedBox(height: 14),
              _TotalRow(label: 'Phí vận chuyển:', value: _formatMoney(order.shippingFee)),
              const SizedBox(height: 14),
              _TotalRow(
                label: 'Giảm giá:',
                value: '-${_formatMoney(order.discount)}',
                valueColor: AppTheme.primary,
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _TotalRow(
                label: 'Tổng cộng:',
                value: _formatMoney(order.totalPrice),
                valueColor: AppTheme.primary,
                large: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool large;

  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: large ? AppTheme.onSurface : AppTheme.onSurfaceVariant)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.onSurface,
            fontSize: large ? 18 : 14,
            fontWeight: large ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusUpdateCard extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;

  const _StatusUpdateCard({
    required this.selectedStatus,
    required this.onChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cập nhật trạng thái',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          const _FieldLabel('Trạng thái đơn hàng'),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            icon: const Icon(Icons.expand_more),
            decoration: const InputDecoration(contentPadding: EdgeInsets.all(16)),
            items: const [
              DropdownMenuItem(value: 'Chờ xác nhận', child: Text('Chờ xác nhận')),
              DropdownMenuItem(value: 'Đang chuẩn bị', child: Text('Đang chuẩn bị')),
              DropdownMenuItem(value: 'Đang vận chuyển', child: Text('Đang vận chuyển')),
              DropdownMenuItem(value: 'Đã giao', child: Text('Đã giao')),
              DropdownMenuItem(value: 'Đã hủy', child: Text('Đã hủy')),
              DropdownMenuItem(value: 'Yêu cầu hoàn', child: Text('Yêu cầu hoàn')),
              DropdownMenuItem(value: 'Đã hoàn', child: Text('Đã hoàn')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
          const SizedBox(height: 18),
          const _FieldLabel('Ghi chú nội bộ'),
          const TextField(
            minLines: 4,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Thêm ghi chú...',
              contentPadding: EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Lưu trạng thái'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: AppTheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final ShopOrder order;

  const _TimelineCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lịch sử đơn hàng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < _items.length; i++)
            _TimelineTile(item: _items[i], isLast: i == _items.length - 1),
        ],
      ),
    );
  }

  List<_TimelineItem> get _items {
    return [
      _TimelineItem(
        title: _statusLabel(order.status),
        time: _formatDateTime(order.statusUpdatedAt ?? order.orderedAt),
        note: 'Trạng thái hiện tại của đơn hàng.',
        icon: Icons.local_shipping_outlined,
        active: true,
      ),
      _TimelineItem(
        title: 'Đơn hàng mới',
        time: _formatDateTime(order.orderedAt),
        icon: Icons.shopping_bag_outlined,
      ),
    ];
  }
}

class _TimelineTile extends StatelessWidget {
  final _TimelineItem item;
  final bool isLast;

  const _TimelineTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final iconBackground = item.active ? AppTheme.primaryContainer : AppTheme.surfaceContainer;
    final iconColor = item.active ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant;
    final textColor = item.active ? AppTheme.onSurface : AppTheme.onSurfaceVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
                child: Icon(item.icon, size: 14, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.time,
                    style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                  ),
                  if (item.note != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.note!,
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
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

class _OrderProduct {
  final String name;
  final String variant;
  final String price;
  final String quantity;
  final String total;
  final String imageUrl;

  const _OrderProduct({
    required this.name,
    required this.variant,
    required this.price,
    required this.quantity,
    required this.total,
    required this.imageUrl,
  });

  factory _OrderProduct.fromItem(OrderItem item) {
    return _OrderProduct(
      name: item.name,
      variant: item.size == null || item.size!.isEmpty
          ? 'Không phân loại'
          : 'Size: ${item.size}',
      price: _formatMoney(item.unitPrice),
      quantity: item.quantity.toString(),
      total: _formatMoney(item.totalPrice),
      imageUrl: item.imageUrl ?? '',
    );
  }
}

String _displayOrderId(String id) => id.startsWith('#') ? id : '#$id';

String _formatMoney(int value) {
  return '${value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  )}đ';
}

String _formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$hour:$minute, $day/$month/${date.year}';
}

bool _isPaid(ShopOrder order) {
  final method = order.paymentMethod.toLowerCase();
  return method.contains('chuyển') || order.status == OrderStatus.completed;
}

String _statusLabel(OrderStatus status) => switch (status) {
      OrderStatus.pendingPayment => 'Chờ xác nhận',
      OrderStatus.pendingConfirmation => 'Chờ xác nhận',
      OrderStatus.preparing => 'Đang chuẩn bị',
      OrderStatus.delivering => 'Đang vận chuyển',
      OrderStatus.completed => 'Đã giao',
      OrderStatus.cancelled => 'Đã hủy',
      OrderStatus.returnRequested => 'Yêu cầu hoàn',
      OrderStatus.returned => 'Đã hoàn',
    };

OrderStatus _statusFromLabel(String label) => switch (label) {
      'Chờ xác nhận' => OrderStatus.pendingConfirmation,
      'Đang chuẩn bị' => OrderStatus.preparing,
      'Đang vận chuyển' => OrderStatus.delivering,
      'Đã giao' => OrderStatus.completed,
      'Đã hủy' => OrderStatus.cancelled,
      'Yêu cầu hoàn' => OrderStatus.returnRequested,
      'Đã hoàn' => OrderStatus.returned,
      _ => OrderStatus.pendingConfirmation,
    };

class _TimelineItem {
  final String title;
  final String time;
  final String? note;
  final IconData icon;
  final bool active;

  const _TimelineItem({
    required this.title,
    required this.time,
    this.note,
    required this.icon,
    this.active = false,
  });
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppTheme.surface,
    border: Border.all(color: AppTheme.outlineVariant),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
