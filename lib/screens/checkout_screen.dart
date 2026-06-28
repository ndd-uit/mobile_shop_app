import 'package:flutter/material.dart';

import '../models/order_item.dart';
import '../models/customer_profile.dart';
import '../models/shop_order.dart';
import '../theme/app_theme.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final CustomerProfile customerProfile;
  final List<OrderItem> items;
  final Future<bool> Function(ShopOrder order) onOrderConfirmed;
  final VoidCallback onGoHome;
  final VoidCallback onViewOrders;

  const CheckoutScreen({
    super.key,
    required this.customerProfile,
    required this.items,
    required this.onOrderConfirmed,
    required this.onGoHome,
    required this.onViewOrders,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController voucherController = TextEditingController();

  String selectedPaymentMethod = 'cod';
  int shippingFee = 30000;
  int discount = 0;
  String? appliedVoucherCode;
  bool orderConfirmed = false;
  bool useSavedCustomerInfo = false;
  String manualName = '';
  String manualPhone = '';
  String manualAddress = '';
  late final String orderNumber;

  static const bankQrUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAFpfV6KRmnxyFKwKbtB1cSfuKsY80ptIdUrI7jpoiziUDBgoOkzqneA7rqrr53Gj8Ud4dgggB41G21Hf_2jwbnUCLmAak5F4xH9YTc0Zu92AsrbraRuWqKzxz-iF5KTpLsn9qzK_fBK6tpbXKy7q3VGlYan2-u_M958C7i5sByoJfpGED7PU9odzyqzD_Eb0CFtJivfSqrC8kEpY0OgNppZDKuzNPdUyo3z3QoPdvOOw638Qi7Z7lBdVvdhAdAaw179Zfrjekj7eg';

  @override
  void initState() {
    super.initState();
    orderNumber = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
  }

  String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}đ';
  }

  int get subtotal =>
      widget.items.fold(0, (sum, item) => sum + item.totalPrice);

  int get totalWithShipping => subtotal + shippingFee - discount;

  void applyVoucher() {
    FocusScope.of(context).unfocus();
    final code = voucherController.text.trim().toUpperCase();
    int newDiscount;
    switch (code) {
      case 'DAISY10':
        newDiscount = (subtotal * 0.1).round().clamp(0, 100000);
      case 'FREESHIP':
        newDiscount = shippingFee;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã giảm giá không hợp lệ hoặc đã hết hạn'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
    }
    setState(() {
      discount = newDiscount;
      appliedVoucherCode = code;
      voucherController.text = code;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã áp dụng mã $code'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void removeVoucher() {
    setState(() {
      discount = 0;
      appliedVoucherCode = null;
      voucherController.clear();
    });
  }

  void toggleSavedCustomerInfo() {
    setState(() {
      if (!useSavedCustomerInfo) {
        manualName = fullNameController.text;
        manualPhone = phoneController.text;
        manualAddress = addressController.text;
        fullNameController.text = widget.customerProfile.name;
        phoneController.text = widget.customerProfile.phoneNumber;
        addressController.text = widget.customerProfile.defaultAddress!.address;
      } else {
        fullNameController.text = manualName;
        phoneController.text = manualPhone;
        addressController.text = manualAddress;
      }
      useSavedCustomerInfo = !useSavedCustomerInfo;
    });
  }

  Future<void> _confirmOrder() async {
    if (fullNameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin giao hàng'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => orderConfirmed = true);
    final now = DateTime.now();
    final order = ShopOrder(
      id: 'DS$orderNumber',
      orderedAt: now,
      status: OrderStatus.delivering,
      items: List.unmodifiable(widget.items),
      shippingFee: shippingFee,
      discount: discount,
      voucherCode: appliedVoucherCode,
      customerName: fullNameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      shippingAddress: addressController.text.trim(),
      paymentMethod: selectedPaymentMethod == 'cod'
          ? 'Thanh toán khi nhận hàng (COD)'
          : 'Chuyển khoản ngân hàng',
    );
    final saved = await widget.onOrderConfirmed(order);
    if (!mounted) return;
    if (!saved) {
      setState(() => orderConfirmed = false);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSuccessScreen(
          order: order,
          onGoHome: widget.onGoHome,
          onViewOrders: widget.onViewOrders,
        ),
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thanh toán',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          SizedBox(width: 40), // Spacer for center alignment
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        children: [
          // Shipping Information Section
          _buildShippingSection(),
          const SizedBox(height: 32),

          // Payment Method Section
          _buildPaymentMethodSection(),
          const SizedBox(height: 32),

          _buildVoucherSection(),
          const SizedBox(height: 32),

          // Order Summary Section
          _buildOrderSummarySection(),
        ],
      ),
      bottomSheet: _buildBottomActionBar(),
    );
  }

  Widget _buildShippingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin giao hàng',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // Full Name
        TextField(
          controller: fullNameController,
          decoration: InputDecoration(
            hintText: 'Họ tên',
            hintStyle: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Phone Number
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Số điện thoại',
            hintStyle: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Address
        TextField(
          controller: addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Địa chỉ nhận hàng (Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành phố)',
            hintStyle: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (widget.customerProfile.hasCompleteShippingInfo) ...[
          const SizedBox(height: 12),
          Material(
            color: useSavedCustomerInfo
                ? AppTheme.primaryContainer.withValues(alpha: 0.25)
                : AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: toggleSavedCustomerInfo,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: useSavedCustomerInfo
                        ? AppTheme.primary
                        : AppTheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      useSavedCustomerInfo
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: useSavedCustomerInfo
                          ? AppTheme.primary
                          : AppTheme.outline,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dùng thông tin đã lưu trong tài khoản',
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.customerProfile.name} • ${widget.customerProfile.defaultAddress!.label}',
                            style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức thanh toán',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // COD Option
        _buildPaymentOption(
          value: 'cod',
          label: 'Thanh toán khi nhận hàng (COD)',
          icon: Icons.local_shipping_outlined,
        ),
        const SizedBox(height: 12),
        // Bank Transfer Option
        _buildPaymentOption(
          value: 'bank_transfer',
          label: 'Chuyển khoản ngân hàng',
          icon: Icons.account_balance_outlined,
        ),
        if (selectedPaymentMethod == 'bank_transfer') ...[
          const SizedBox(height: 14),
          _buildBankTransferDetails(),
        ],
      ],
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppTheme.primaryContainer : AppTheme.surface,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : AppTheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.onPrimaryContainer
                      : AppTheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTransferDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 188,
            height: 188,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.network(
              bankQrUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 92, color: AppTheme.primary),
                  Text('QR chuyển khoản'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _BankInfoRow(label: 'Ngân hàng', value: 'MB Bank'),
          const _BankInfoRow(label: 'Số tài khoản', value: '1234567890'),
          const _BankInfoRow(label: 'Chủ tài khoản', value: 'DAISY SHOP'),
          _BankInfoRow(
            label: 'Nội dung chuyển khoản',
            value: 'DS$orderNumber',
            emphasized: true,
          ),
          const SizedBox(height: 8),
          const Text(
            'Đơn hàng sẽ được xác nhận sau khi shop kiểm tra thanh toán.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mã giảm giá',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: voucherController,
                enabled: appliedVoucherCode == null,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => applyVoucher(),
                decoration: InputDecoration(
                  hintText: 'Nhập mã giảm giá',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  suffixIcon: appliedVoucherCode == null
                      ? null
                      : IconButton(
                          onPressed: removeVoucher,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: appliedVoucherCode == null ? applyVoucher : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: AppTheme.onSecondary,
                minimumSize: const Size(92, 48),
              ),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Mã thử nghiệm: DAISY10 hoặc FREESHIP',
          style: TextStyle(color: AppTheme.outline, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildOrderSummarySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tóm tắt đơn hàng',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < widget.items.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _buildOrderItem(widget.items[index]),
          ],
          const SizedBox(height: 16),
          Divider(color: AppTheme.outlineVariant, thickness: 1),
          const SizedBox(height: 16),
          // Calculations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tạm tính',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              Text(
                formatPrice(subtotal),
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phí vận chuyển',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              Text(
                formatPrice(shippingFee),
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (discount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giảm giá${appliedVoucherCode != null ? ' ($appliedVoucherCode)' : ''}',
                  style: const TextStyle(color: AppTheme.primary, fontSize: 14),
                ),
                Text(
                  '-${formatPrice(discount)}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Divider(color: AppTheme.outlineVariant, thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatPrice(totalWithShipping),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
          child: Container(
            width: 60,
            height: 72,
            color: AppTheme.surfaceContainerHigh,
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppTheme.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(width: 12),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'x${item.quantity}${item.size != null ? ', Size ${item.size}' : ''}',
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatPrice(item.totalPrice),
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: orderConfirmed ? null : _confirmOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: AppTheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              orderConfirmed
                  ? 'Đã đặt hàng'
                  : selectedPaymentMethod == 'bank_transfer'
                  ? 'Tôi đã chuyển khoản'
                  : 'Xác nhận đặt hàng',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _BankInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _BankInfoRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: emphasized ? AppTheme.primary : AppTheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
