import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/customer_profile.dart';
import '../theme/app_theme.dart';

class AccountScreen extends StatefulWidget {
  final CustomerProfile profile;
  final ValueChanged<CustomerProfile> onProfileChanged;
  final VoidCallback onViewOrders;
  final VoidCallback onEditProfile;
  final VoidCallback onManageAddresses;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onViewFavorites;
  final VoidCallback? onLogout;

  const AccountScreen({
    super.key,
    required this.profile,
    required this.onProfileChanged,
    required this.onViewOrders,
    required this.onEditProfile,
    required this.onManageAddresses,
    this.onOpenSettings,
    this.onViewFavorites,
    this.onLogout,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;
    widget.onProfileChanged(widget.profile.copyWith(avatarPath: image.path));
  }

  void confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi Daisy Shop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onLogout?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _AccountMenuItem(
            icon: Icons.person,
            label: 'Thông tin tài khoản',
            onTap: widget.onEditProfile,
          ),
          const SizedBox(height: 8),
          _AccountMenuItem(
            icon: Icons.receipt_long,
            label: 'Đơn hàng của tôi',
            onTap: widget.onViewOrders,
          ),
          const SizedBox(height: 8),
          _AccountMenuItem(
            icon: Icons.favorite,
            label: 'Sản phẩm yêu thích',
            onTap:
                widget.onViewFavorites ??
                () => showMessage('Sản phẩm yêu thích đang được cập nhật'),
          ),
          const SizedBox(height: 8),
          _AccountMenuItem(
            icon: Icons.location_on,
            label: 'Địa chỉ nhận hàng',
            onTap: widget.onManageAddresses,
          ),
          const SizedBox(height: 8),
          _AccountMenuItem(
            icon: Icons.settings,
            label: 'Cài đặt',
            onTap:
                widget.onOpenSettings ??
                () => showMessage('Cài đặt đang được phát triển'),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: confirmLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Đăng xuất',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 4),
                ),
                child: ClipOval(
                  child: widget.profile.avatarPath != null
                      ? Image.file(
                          File(widget.profile.avatarPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarFallback(),
                        )
                      : Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBR_6aGl0fFKnItnD2QxDSSyP74GeDlkD6ha5L9AvPM9NwAZU37mKY1Xnyj5XL969P9irgxAfqlWeCvn9OQ5Tq20fMxX3DNVs4zrO4Jcr6vXY3UeeF7uXErdSaerz6MhlobsM9N8BhCUjtw-6FVqHcYnz8mLgM_0SX9rxhZKfGPDa4UP5m-m1JgFsPWljvAl9mM345FFBQb9HJKG01pDewJDsb_CTmBFCgUak3lwx2Ij8AWUx4cDg82_vJ-idLEMp5Mvrlha1ETeEg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarFallback(),
                        ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: 0,
                child: Material(
                  color: AppTheme.primaryContainer,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    onTap: pickAvatar,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: AppTheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.profile.name,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phone_iphone,
                size: 16,
                color: AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                widget.profile.phoneNumber,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppTheme.primaryFixed,
      child: const Icon(Icons.person, size: 52, color: AppTheme.primary),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primary, size: 21),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
