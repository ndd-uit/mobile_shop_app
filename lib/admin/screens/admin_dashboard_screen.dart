import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/shop_order.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/admin_feedback.dart';
import '../widgets/admin_shell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_DashboardData> dashboardFuture;

  @override
  void initState() {
    super.initState();
    dashboardFuture = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    final results = await Future.wait([
      ProductService.fetchAdminAll(),
      OrderService.fetchAdminAll(),
    ]);
    final products = results[0] as List<Product>;
    final orders = results[1] as List<ShopOrder>;
    return _DashboardData.fromDb(products: products, orders: orders);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminShell(
            currentSection: AdminSection.dashboard,
            child: AdminStatePanel.loading(),
          );
        }
        if (snapshot.hasError) {
          return AdminShell(
            currentSection: AdminSection.dashboard,
            child: AdminStatePanel.error(
              onAction: () => setState(() {
                dashboardFuture = _loadDashboard();
              }),
            ),
          );
        }
        final data = snapshot.data ?? _DashboardData.empty();
        return AdminShell(
          currentSection: AdminSection.dashboard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 4
                  : constraints.maxWidth >= 640
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: columns == 1 ? 3.4 : 2.2,
                children: [
                  _SummaryCard(
                    label: 'Tổng đơn hàng',
                    value: _formatNumber(data.totalOrders),
                    note: 'Từ dữ liệu DB',
                    icon: Icons.shopping_bag,
                    tone: Color(0xFF168A45),
                    iconBackground: Color(0xFFE2F4E8),
                    noteIcon: Icons.trending_up,
                  ),
                  _SummaryCard(
                    label: 'Đơn chờ xử lý',
                    value: _formatNumber(data.pendingOrders),
                    note: 'Cần xử lý ngay',
                    icon: Icons.pending_actions,
                    tone: Color(0xFF8A515C),
                    iconBackground: Color(0xFFF8ECEF),
                    noteIcon: Icons.sentiment_neutral_outlined,
                  ),
                  _SummaryCard(
                    label: 'Sản phẩm sắp hết',
                    value: _formatNumber(data.lowStockCount),
                    note: 'Cần nhập thêm',
                    icon: Icons.inventory_2_outlined,
                    tone: AppTheme.error,
                    iconBackground: AppTheme.errorContainer,
                    noteIcon: Icons.warning_amber,
                  ),
                  _SummaryCard(
                    label: 'Tổng sản phẩm',
                    value: _formatNumber(data.activeProducts),
                    note: 'Đang kinh doanh',
                    icon: Icons.layers,
                    tone: AppTheme.secondary,
                    iconBackground: AppTheme.surfaceContainerHigh,
                    noteIcon: Icons.category_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 980;
              if (!desktop) {
                return Column(
                  children: [
                    _RecentOrdersPanel(orders: data.recentOrders),
                    const SizedBox(height: 12),
                    _LowStockPanel(products: data.lowStockProducts),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: SizedBox(
                      height: 500,
                      child: _RecentOrdersPanel(orders: data.recentOrders),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 500,
                      child: _LowStockPanel(products: data.lowStockProducts),
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
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color tone;
  final Color iconBackground;
  final IconData noteIcon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.tone,
    required this.iconBackground,
    required this.noteIcon,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(noteIcon, size: 15, color: tone),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tone,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: tone),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  final List<_RecentOrder> orders;

  const _RecentOrdersPanel({required this.orders});

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Đơn hàng mới nhất',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
              ],
            ),
          ),
          const Divider(height: 1),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa có đơn hàng.',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            )
          else
            _OrdersTable(orders: orders),
        ],
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  final List<_RecentOrder> orders;

  const _OrdersTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.55),
        2: FlexColumnWidth(1.25),
        3: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: AppTheme.surfaceContainerLow),
          children: [
            _TableHeader('Mã đơn hàng'),
            _TableHeader('Khách hàng'),
            _TableHeader('Trạng thái'),
            _TableHeader('Tổng cộng', alignRight: true),
          ],
        ),
        for (final order in orders)
          TableRow(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.surfaceContainerHighest),
              ),
            ),
            children: [
              _TableCell(
                order.id,
                    color: const Color(0xFF8A515C),
                fontWeight: FontWeight.w700,
              ),
              _TableCell(order.customer),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusPill(label: order.status, tone: order.tone),
                ),
              ),
              _TableCell(
                _formatPrice(order.total),
                alignRight: true,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: AppTheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool alignRight;
  final Color? color;
  final FontWeight fontWeight;

  const _TableCell(
    this.text, {
    this.alignRight = false,
    this.color,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(color: color, fontWeight: fontWeight),
      ),
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  final List<_LowStockProduct> products;

  const _LowStockPanel({required this.products});

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Sản phẩm sắp hết hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              children: [
                if (products.isEmpty)
                  const Text(
                    'Không có sản phẩm sắp hết hàng.',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  )
                else
                  for (final product in products) ...[
                    _LowStockTile(product: product),
                    if (product != products.last) const SizedBox(height: 14),
                  ],
                const Spacer(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Nhập hàng hàng loạt',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final _LowStockProduct product;

  const _LowStockTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final tone = product.stock <= 5 ? AppTheme.error : const Color(0xFF8A515C);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.imageUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 56,
              height: 56,
              color: AppTheme.surfaceContainerLow,
              child: const Icon(Icons.image_not_supported_outlined),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: product.stockRatio,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: const Color(0xFFF1EEEE),
                valueColor: AlwaysStoppedAnimation(tone),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.stock}',
                style: TextStyle(
                  color: tone,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Còn lại',
                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final _OrderTone tone;

  const _StatusPill({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _OrderTone.success => (const Color(0xFFE1F5E8), const Color(0xFF118548)),
      _OrderTone.primary => (const Color(0xFFFFC1D1), const Color(0xFF8A515C)),
      _OrderTone.secondary => (const Color(0xFFD9DADB), const Color(0xFF5D5F5F)),
      _OrderTone.neutral => (const Color(0xFFD9DADB), const Color(0xFF5D5F5F)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _AdminCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RecentOrder {
  final String id;
  final String customer;
  final String status;
  final int total;
  final _OrderTone tone;

  const _RecentOrder(this.id, this.customer, this.status, this.total, this.tone);

  factory _RecentOrder.fromOrder(ShopOrder order) {
    return _RecentOrder(
      order.id.startsWith('#') ? order.id : '#${order.id}',
      order.customerName,
      _statusLabel(order.status),
      order.totalPrice,
      _toneForStatus(order.status),
    );
  }
}

class _LowStockProduct {
  final String name;
  final int stock;
  final double stockRatio;
  final String imageUrl;

  const _LowStockProduct(this.name, this.stock, this.stockRatio, this.imageUrl);

  factory _LowStockProduct.fromProduct(Product product) {
    return _LowStockProduct(
      product.name,
      product.stock,
      (product.stock / 20).clamp(0.0, 1.0),
      product.imageUrl,
    );
  }
}

enum _OrderTone { success, primary, secondary, neutral }

class _DashboardData {
  final int totalOrders;
  final int pendingOrders;
  final int lowStockCount;
  final int activeProducts;
  final List<_RecentOrder> recentOrders;
  final List<_LowStockProduct> lowStockProducts;

  const _DashboardData({
    required this.totalOrders,
    required this.pendingOrders,
    required this.lowStockCount,
    required this.activeProducts,
    required this.recentOrders,
    required this.lowStockProducts,
  });

  factory _DashboardData.empty() {
    return const _DashboardData(
      totalOrders: 0,
      pendingOrders: 0,
      lowStockCount: 0,
      activeProducts: 0,
      recentOrders: [],
      lowStockProducts: [],
    );
  }

  factory _DashboardData.fromDb({
    required List<Product> products,
    required List<ShopOrder> orders,
  }) {
    final activeProducts = products.where((product) => product.isActive).toList();
    final lowStockProducts = activeProducts
        .where((product) => product.stock > 0 && product.stock <= 7)
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
    final pendingOrders = orders.where((order) {
      return order.status == OrderStatus.pendingPayment ||
          order.status == OrderStatus.pendingConfirmation;
    }).length;

    return _DashboardData(
      totalOrders: orders.length,
      pendingOrders: pendingOrders,
      lowStockCount: lowStockProducts.length,
      activeProducts: activeProducts.length,
      recentOrders: orders.take(5).map(_RecentOrder.fromOrder).toList(),
      lowStockProducts: lowStockProducts
          .take(4)
          .map(_LowStockProduct.fromProduct)
          .toList(),
    );
  }
}

String _statusLabel(OrderStatus status) => switch (status) {
      OrderStatus.pendingPayment => 'Chờ xử lý',
      OrderStatus.pendingConfirmation => 'Chờ xử lý',
      OrderStatus.preparing => 'Đang chuẩn bị',
      OrderStatus.delivering => 'Đang giao',
      OrderStatus.completed => 'Hoàn tất',
      OrderStatus.cancelled => 'Đã hủy',
      OrderStatus.returnRequested => 'Yêu cầu hoàn',
      OrderStatus.returned => 'Đã hoàn',
    };

_OrderTone _toneForStatus(OrderStatus status) => switch (status) {
      OrderStatus.pendingPayment => _OrderTone.primary,
      OrderStatus.pendingConfirmation => _OrderTone.primary,
      OrderStatus.preparing => _OrderTone.secondary,
      OrderStatus.delivering => _OrderTone.secondary,
      OrderStatus.completed => _OrderTone.success,
      OrderStatus.cancelled => _OrderTone.neutral,
      OrderStatus.returnRequested => _OrderTone.primary,
      OrderStatus.returned => _OrderTone.neutral,
    };

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
}

String _formatPrice(int value) {
  final text = value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '$textđ';
}
