import 'package:flutter/material.dart';

import '../models/shop_order.dart';
import '../theme/app_theme.dart';

class OrderSuccessScreen extends StatefulWidget {
  final ShopOrder order;
  final VoidCallback onGoHome;
  final VoidCallback onViewOrders;

  const OrderSuccessScreen({
    super.key,
    required this.order,
    required this.onGoHome,
    required this.onViewOrders,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController animationController;
  late final AnimationController pulseController;
  late final Animation<double> scaleAnimation;
  late final Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    scaleAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.elasticOut,
    );
    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.2, 1, curve: Curves.easeOut),
    );
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  void navigateTo(VoidCallback changeTab) {
    changeTab();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.surface,
          centerTitle: true,
          title: const Text(
            'Daisy Shop',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 28),
                          ScaleTransition(
                            scale: scaleAnimation,
                            child: SizedBox(
                              width: 170,
                              height: 170,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: pulseController,
                                    builder: (context, _) {
                                      return _buildPulseRing(
                                        pulseController.value,
                                      );
                                    },
                                  ),
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryContainer,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withValues(
                                            alpha: 0.16,
                                          ),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 52,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Đặt hàng thành công',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: const Text(
                              'Cảm ơn bạn đã mua sắm tại Daisy Shop. Đơn hàng của bạn đang được chúng tôi xử lý.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          _buildOrderSummary(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => navigateTo(widget.onGoHome),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      foregroundColor: AppTheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Quay về trang chủ'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => navigateTo(widget.onViewOrders),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primaryContainer),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Xem đơn hàng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRing(double progress) {
    return Opacity(
      opacity: (1 - progress) * 0.42,
      child: Transform.scale(
        scale: 1 + progress * 0.7,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryContainer, width: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
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
          _SummaryRow(
            icon: Icons.receipt_long_outlined,
            label: 'Mã đơn hàng',
            value: '#${widget.order.id}',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: AppTheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          _SummaryRow(
            icon: Icons.payments_outlined,
            label: 'Tổng tiền',
            value: formatPrice(widget.order.totalPrice),
            emphasize: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: AppTheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 19,
                color: AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Trạng thái',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: AppTheme.tertiary),
                    SizedBox(width: 6),
                    Text(
                      'Đang xử lý',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 8),
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
          value,
          style: TextStyle(
            color: emphasize ? AppTheme.primary : AppTheme.onSurface,
            fontSize: emphasize ? 20 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
