import 'package:flutter/material.dart';

import '../../models/shop_order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/admin_feedback.dart';
import '../widgets/admin_shell.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String query = '';
  String selectedStatus = 'Tất cả';
  String payment = 'Thanh toán';
  late Future<List<_AdminOrder>> ordersFuture;

  @override
  void initState() {
    super.initState();
    ordersFuture = _loadOrders();
  }

  Future<List<_AdminOrder>> _loadOrders() async {
    final orders = await OrderService.fetchAdminAll();
    return orders.map(_AdminOrder.fromShopOrder).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_AdminOrder>>(
      future: ordersFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final allOrders = snapshot.data ?? const <_AdminOrder>[];
        final orders = allOrders.where((order) {
          final matchesQuery = query.isEmpty ||
              order.id.toLowerCase().contains(query.toLowerCase()) ||
              order.customer.toLowerCase().contains(query.toLowerCase()) ||
              order.phone.contains(query);
          final matchesStatus =
              selectedStatus == 'Tất cả' || order.orderStatus == selectedStatus;
          final matchesPayment = payment == 'Thanh toán' ||
              (payment == 'Đã trả' && order.paymentPaid) ||
              (payment == 'Chưa trả' && !order.paymentPaid);
          return matchesQuery && matchesStatus && matchesPayment;
        }).toList();

        return AdminShell(
          currentSection: AdminSection.orders,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PageHeader(),
              const SizedBox(height: 24),
              _OrderFilters(
                selectedStatus: selectedStatus,
                payment: payment,
                onQueryChanged: (value) => setState(() => query = value),
                onStatusChanged: (value) => setState(() => selectedStatus = value),
                onPaymentChanged: (value) => setState(() => payment = value),
              ),
              const SizedBox(height: 20),
              if (loading)
                const AdminStatePanel.loading()
              else if (snapshot.hasError)
                AdminStatePanel.error(onAction: _refreshOrders)
              else if (orders.isEmpty)
                AdminStatePanel.empty(
                  title: 'Không tìm thấy đơn hàng',
                  message: 'Thử đổi bộ lọc hoặc từ khóa để xem thêm đơn hàng.',
                  actionLabel: 'Xóa bộ lọc',
                  onAction: _clearFilters,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 760) {
                      return _MobileOrderList(
                        orders: orders,
                        onConfirm: _confirmOrder,
                      );
                    }
                    return _OrdersTable(
                      orders: orders,
                      onConfirm: _confirmOrder,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _refreshOrders() {
    setState(() => ordersFuture = _loadOrders());
  }

  void _clearFilters() {
    setState(() {
      query = '';
      selectedStatus = 'Tất cả';
      payment = 'Thanh toán';
    });
  }

  Future<void> _confirmOrder(_AdminOrder order) async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: 'Xác nhận đơn hàng?',
      message: 'Đơn ${order.id} sẽ chuyển sang bước chuẩn bị hàng.',
      confirmLabel: 'Xác nhận',
    );
    if (!confirmed || !mounted) return;
    try {
      await OrderService.updateAdminStatus(
        id: order.rawId,
        status: OrderStatus.preparing,
      );
      if (!mounted) return;
      _refreshOrders();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không cập nhật được đơn hàng: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xác nhận ${order.id}'), behavior: SnackBarBehavior.floating),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final title = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý đơn hàng',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Theo dõi và xử lý các đơn hàng từ khách hàng.',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        );
        final export = FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Xuất báo cáo'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryContainer,
            foregroundColor: AppTheme.onPrimaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 12), export],
          );
        }
        return Row(children: [Expanded(child: title), export]);
      },
    );
  }
}

class _OrderFilters extends StatelessWidget {
  final String selectedStatus;
  final String payment;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPaymentChanged;

  const _OrderFilters({
    required this.selectedStatus,
    required this.payment,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onPaymentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      'Tất cả',
      'Chờ xác nhận',
      'Đang chuẩn bị',
      'Đang vận chuyển',
      'Đã giao',
      'Đã hủy',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  hintText: 'Tìm mã đơn, khách hàng, SĐT...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                initialValue: payment,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                items: const [
                  DropdownMenuItem(value: 'Thanh toán', child: Text('Thanh toán')),
                  DropdownMenuItem(value: 'Đã trả', child: Text('Đã trả')),
                  DropdownMenuItem(value: 'Chưa trả', child: Text('Chưa trả')),
                ],
                onChanged: (value) {
                  if (value != null) onPaymentChanged(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in filters) ...[
                _FilterChip(
                  label: filter,
                  selected: selectedStatus == filter,
                  onTap: () => onStatusChanged(filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryContainer : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  final List<_AdminOrder> orders;
  final ValueChanged<_AdminOrder> onConfirm;

  const _OrdersTable({required this.orders, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Table(
            columnWidths: const {
              0: FlexColumnWidth(0.78),
              1: FlexColumnWidth(1.55),
              2: FlexColumnWidth(1.04),
              3: FlexColumnWidth(1.0),
              4: FlexColumnWidth(0.82),
              5: FlexColumnWidth(0.86),
              6: FlexColumnWidth(1.1),
              7: FlexColumnWidth(0.9),
              8: FlexColumnWidth(1.35),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: AppTheme.surfaceContainerLow),
                children: [
                  _HeaderCell('Mã đơn'),
                  _HeaderCell('Khách hàng'),
                  _HeaderCell('SĐT'),
                  _HeaderCell('Tổng', alignRight: true),
                  _HeaderCell('PTTT'),
                  _HeaderCell('TTTT'),
                  _HeaderCell('Đơn hàng'),
                  _HeaderCell('Ngày'),
                  _HeaderCell('Thao tác', alignRight: true),
                ],
              ),
              for (final order in orders) _orderRow(order),
            ],
          ),
          const _Pagination(),
        ],
      ),
    );
  }

  TableRow _orderRow(_AdminOrder order) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
      ),
      children: [
        _BodyCell(order.id, color: AppTheme.primary, fontWeight: FontWeight.w700),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            children: [
              _InitialsAvatar(order.initials),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        _BodyCell(order.phone, muted: true),
        _BodyCell(order.total, alignRight: true, fontWeight: FontWeight.w700),
        _BodyCell(order.paymentMethod, muted: true),
        _PaymentStatusCell(order: order),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _OrderStatusBadge(label: order.orderStatus, tone: order.statusTone),
          ),
        ),
        _BodyCell(order.createdAt, muted: true),
        _ActionsCell(
          order: order,
          canConfirm: order.canConfirm,
          onConfirm: () => onConfirm(order),
        ),
      ],
    );
  }
}

class _MobileOrderList extends StatelessWidget {
  final List<_AdminOrder> orders;
  final ValueChanged<_AdminOrder> onConfirm;

  const _MobileOrderList({required this.orders, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final order in orders) ...[
          _MobileOrderCard(order: order, onConfirm: () => onConfirm(order)),
          if (order != orders.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MobileOrderCard extends StatelessWidget {
  final _AdminOrder order;
  final VoidCallback onConfirm;

  const _MobileOrderCard({required this.order, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customer,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _OrderStatusBadge(label: order.orderStatus, tone: order.statusTone),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MobileMeta(icon: Icons.call, text: order.phone)),
              _MobileMeta(
                icon: order.paymentMethod == 'COD' ? Icons.payments : Icons.account_balance,
                text: order.paymentMethod == 'COD' ? 'COD' : 'CK',
              ),
            ],
          ),
          if (order.createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _MobileMeta(icon: Icons.calendar_today, text: order.createdAt),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.total,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/admin/orders/detail',
                  arguments: {'id': order.rawId},
                ),
                child: const Text('Chi tiết'),
              ),
              if (order.canConfirm) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    foregroundColor: AppTheme.onPrimaryContainer,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MobileMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _HeaderCell(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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

class _BodyCell extends StatelessWidget {
  final String text;
  final bool alignRight;
  final bool muted;
  final Color? color;
  final FontWeight fontWeight;

  const _BodyCell(
    this.text, {
    this.alignRight = false,
    this.muted = false,
    this.color,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? (muted ? AppTheme.onSurfaceVariant : AppTheme.onSurface),
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;

  const _InitialsAvatar(this.initials);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppTheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PaymentStatusCell extends StatelessWidget {
  final _AdminOrder order;

  const _PaymentStatusCell({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
      child: Text(
        order.paymentStatus,
        style: TextStyle(
          color: order.paymentPaid ? AppTheme.primary : AppTheme.error,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final String label;
  final _OrderStatusTone tone;

  const _OrderStatusBadge({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _OrderStatusTone.primary => (AppTheme.primaryContainer, AppTheme.onPrimaryContainer),
      _OrderStatusTone.secondary => (AppTheme.secondaryContainer, AppTheme.onSecondaryContainer),
      _OrderStatusTone.neutral => (AppTheme.surfaceContainerHighest, AppTheme.onSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionsCell extends StatelessWidget {
  final _AdminOrder order;
  final bool canConfirm;
  final VoidCallback onConfirm;

  const _ActionsCell({
    required this.order,
    required this.canConfirm,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 2,
        runSpacing: 2,
        children: [
          if (canConfirm)
            TextButton(
              onPressed: onConfirm,
              style: _compactActionStyle(),
              child: const Text('Xác nhận'),
            ),
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/admin/orders/detail',
              arguments: {'id': order.rawId},
            ),
            style: _compactActionStyle(foregroundColor: AppTheme.secondary),
            child: const Text('Chi tiết'),
          ),
        ],
      ),
    );
  }

  ButtonStyle _compactActionStyle({Color? foregroundColor}) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor,
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Hiển thị 1-3 của 45 đơn hàng',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          IconButton(onPressed: null, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _AdminOrder {
  final String rawId;
  final String id;
  final String customer;
  final String initials;
  final String phone;
  final String total;
  final String paymentMethod;
  final String paymentStatus;
  final bool paymentPaid;
  final String orderStatus;
  final _OrderStatusTone statusTone;
  final String createdAt;
  final bool canConfirm;

  const _AdminOrder({
    required this.rawId,
    required this.id,
    required this.customer,
    required this.initials,
    required this.phone,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentPaid,
    required this.orderStatus,
    required this.statusTone,
    required this.createdAt,
    this.canConfirm = false,
  });

  factory _AdminOrder.fromShopOrder(ShopOrder order) {
    final paymentPaid = order.paymentMethod.toLowerCase().contains('chuyển') ||
        order.status == OrderStatus.completed;
    final orderStatus = _statusLabel(order.status);
    return _AdminOrder(
      rawId: order.id,
      id: order.id.startsWith('#') ? order.id : '#${order.id}',
      customer: order.customerName,
      initials: _initials(order.customerName),
      phone: order.phoneNumber,
      total: _formatPrice(order.totalPrice),
      paymentMethod: _paymentMethodLabel(order.paymentMethod),
      paymentStatus: paymentPaid ? 'Đã trả' : 'Chưa trả',
      paymentPaid: paymentPaid,
      orderStatus: orderStatus,
      statusTone: _statusTone(order.status),
      createdAt: _formatDate(order.orderedAt),
      canConfirm: order.status == OrderStatus.pendingConfirmation ||
          order.status == OrderStatus.pendingPayment,
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _formatPrice(int price) {
    return '${price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    )}₫';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String _paymentMethodLabel(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('cod') || lower.contains('nhận hàng')) return 'COD';
    if (lower.contains('chuyển')) return 'Chuyển khoản';
    return method;
  }

  static String _statusLabel(OrderStatus status) => switch (status) {
        OrderStatus.pendingPayment => 'Chờ xác nhận',
        OrderStatus.pendingConfirmation => 'Chờ xác nhận',
        OrderStatus.preparing => 'Đang chuẩn bị',
        OrderStatus.delivering => 'Đang vận chuyển',
        OrderStatus.completed => 'Đã giao',
        OrderStatus.cancelled => 'Đã hủy',
        OrderStatus.returnRequested => 'Yêu cầu hoàn',
        OrderStatus.returned => 'Đã hoàn',
      };

  static _OrderStatusTone _statusTone(OrderStatus status) => switch (status) {
        OrderStatus.pendingPayment => _OrderStatusTone.primary,
        OrderStatus.pendingConfirmation => _OrderStatusTone.primary,
        OrderStatus.preparing => _OrderStatusTone.secondary,
        OrderStatus.delivering => _OrderStatusTone.secondary,
        OrderStatus.completed => _OrderStatusTone.neutral,
        OrderStatus.cancelled => _OrderStatusTone.neutral,
        OrderStatus.returnRequested => _OrderStatusTone.primary,
        OrderStatus.returned => _OrderStatusTone.neutral,
      };
}

enum _OrderStatusTone { primary, secondary, neutral }

BoxDecoration _panelDecoration() {
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
