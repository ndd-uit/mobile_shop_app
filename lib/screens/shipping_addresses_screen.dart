import 'package:flutter/material.dart';

import '../models/customer_profile.dart';
import '../models/shipping_address.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class ShippingAddressesScreen extends StatefulWidget {
  final CustomerProfile profile;
  final ValueChanged<CustomerProfile> onProfileChanged;
  final VoidCallback onBack;

  const ShippingAddressesScreen({
    super.key,
    required this.profile,
    required this.onProfileChanged,
    required this.onBack,
  });

  @override
  State<ShippingAddressesScreen> createState() =>
      _ShippingAddressesScreenState();
}

class _ShippingAddressesScreenState extends State<ShippingAddressesScreen> {
  late CustomerProfile profile;

  @override
  void initState() {
    super.initState();
    profile = widget.profile;
  }

  void updateProfile(CustomerProfile value) {
    setState(() => profile = value);
    widget.onProfileChanged(value);
  }

  CustomerProfile withAddresses(
    List<ShippingAddress> addresses,
    String? defaultAddressId,
  ) {
    return CustomerProfile(
      name: profile.name,
      phoneNumber: profile.phoneNumber,
      avatarPath: profile.avatarPath,
      addresses: List.unmodifiable(addresses),
      defaultAddressId: defaultAddressId,
    );
  }

  void showAddressForm([ShippingAddress? existing]) {
    showModalBottomSheet<ShippingAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _AddressFormWidget(existing: existing),
    ).then((newAddress) async {
      if (newAddress == null || !mounted) return;

      final uid = AuthService.currentUserId;
      if (uid == null) return;

      try {
        final isNew = existing == null;
        if (isNew) {
          // Thêm mới vào DB, lấy lại address với id đã tạo
          final saved = await ProfileService.addAddress(
            uid: uid,
            label: newAddress.label,
            address: newAddress.address,
          );
          final addresses = [...profile.addresses, saved];
          final defaultId = profile.defaultAddressId ?? saved.id;
          updateProfile(withAddresses(addresses, defaultId));
        } else {
          // Cập nhật DB
          await ProfileService.updateAddress(newAddress);
          final addresses = [...profile.addresses];
          final index = addresses.indexWhere((a) => a.id == newAddress.id);
          if (index != -1) addresses[index] = newAddress;
          updateProfile(withAddresses(addresses, profile.defaultAddressId));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu địa chỉ. Vui lòng thử lại.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> deleteAddress(ShippingAddress address) async {
    try {
      await ProfileService.deleteAddress(address.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa địa chỉ. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final addresses = profile.addresses
        .where((a) => a.id != address.id)
        .toList();
    final defaultId = profile.defaultAddressId == address.id
        ? (addresses.isEmpty ? null : addresses.first.id)
        : profile.defaultAddressId;
    updateProfile(withAddresses(addresses, defaultId));
  }

  Future<void> setDefaultAddress(ShippingAddress address) async {
    final updated = withAddresses(profile.addresses, address.id);
    updateProfile(updated);
    try {
      await ProfileService.save(updated);
    } catch (e) {
      // rollback
      if (!mounted) return;
      updateProfile(profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật địa chỉ mặc định.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        centerTitle: true,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Địa chỉ nhận hàng',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: profile.addresses.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profile.addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = profile.addresses[index];
                return _buildAddressCard(address);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddressForm,
        backgroundColor: AppTheme.primaryContainer,
        foregroundColor: AppTheme.onPrimaryContainer,
        icon: const Icon(Icons.add),
        label: const Text('Thêm địa chỉ'),
      ),
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
              Icons.location_on_outlined,
              size: 68,
              color: AppTheme.primaryContainer,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có địa chỉ nhận hàng',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thêm địa chỉ để điền thông tin checkout nhanh hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(ShippingAddress address) {
    final selected = profile.defaultAddress?.id == address.id;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setDefaultAddress(address),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppTheme.primary : AppTheme.outline,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Mặc định',
                          style: TextStyle(
                            color: AppTheme.onPrimaryContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address.address,
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') showAddressForm(address);
              if (value == 'delete') deleteAddress(address);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
              PopupMenuItem(value: 'delete', child: Text('Xóa')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressFormWidget extends StatefulWidget {
  final ShippingAddress? existing;

  const _AddressFormWidget({this.existing});

  @override
  State<_AddressFormWidget> createState() => _AddressFormWidgetState();
}

class _AddressFormWidgetState extends State<_AddressFormWidget> {
  late TextEditingController labelController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    labelController = TextEditingController(
      text: widget.existing?.label ?? 'Nhà riêng',
    );
    addressController = TextEditingController(text: widget.existing?.address);
  }

  @override
  void dispose() {
    labelController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'Thêm địa chỉ' : 'Sửa địa chỉ',
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: labelController,
            decoration: const InputDecoration(
              labelText: 'Tên địa chỉ',
              hintText: 'Nhà riêng, Công ty...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ đầy đủ',
              hintText: 'Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final label = labelController.text.trim();
                final address = addressController.text.trim();
                if (label.isEmpty || address.isEmpty) return;

                FocusScope.of(context).unfocus();

                final id =
                    widget.existing?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString();
                final newAddress = ShippingAddress(
                  id: id,
                  label: label,
                  address: address,
                );

                Navigator.pop(context, newAddress);
              },
              child: const Text('Lưu địa chỉ'),
            ),
          ),
        ],
      ),
    );
  }
}
