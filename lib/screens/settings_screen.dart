import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;
  bool promotionNotifications = true;
  bool twoFactorAuthentication = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1100),
      ),
    );
  }

  void showChangePasswordDialog() {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ChangePasswordDialog(
        onMessage: showMessage,
      ),
    ).then((success) {
      if (success == true) {
        showMessage('Đã cập nhật mật khẩu');
      }
    });
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
          'Cài đặt',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _SettingsSection(
            title: 'Thanh toán',
            children: [
              _SettingsTile(
                icon: Icons.payments_outlined,
                title: 'Phương thức thanh toán',
                subtitle: 'Quản lý thẻ và tài khoản ngân hàng',
                onTap: () =>
                    showMessage('Phương thức thanh toán đang được cập nhật'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Thông báo',
            children: [
              _SettingsSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Thông báo đẩy',
                subtitle: 'Cập nhật đơn hàng và hoạt động tài khoản',
                value: pushNotifications,
                onChanged: (value) {
                  setState(() => pushNotifications = value);
                },
              ),
              _SettingsSwitchTile(
                icon: Icons.redeem_outlined,
                title: 'Ưu đãi và khuyến mãi',
                subtitle: 'Nhận tin về sản phẩm mới và mã giảm giá',
                value: promotionNotifications,
                onChanged: (value) {
                  setState(() => promotionNotifications = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Bảo mật',
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Đổi mật khẩu',
                onTap: showChangePasswordDialog,
              ),
              _SettingsSwitchTile(
                icon: Icons.verified_user_outlined,
                title: 'Xác thực hai lớp',
                subtitle: twoFactorAuthentication
                    ? 'Đang bật'
                    : 'Tăng cường bảo vệ tài khoản',
                value: twoFactorAuthentication,
                onChanged: (value) {
                  setState(() => twoFactorAuthentication = value);
                  showMessage(
                    value
                        ? 'Đã bật xác thực hai lớp'
                        : 'Đã tắt xác thực hai lớp',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Hỗ trợ',
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Trung tâm trợ giúp',
                onTap: () =>
                    showMessage('Trung tâm trợ giúp đang được cập nhật'),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Điều khoản dịch vụ',
                onTap: () =>
                    showMessage('Điều khoản dịch vụ đang được cập nhật'),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Về Daisy Shop',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Daisy Shop',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.local_florist,
                    color: AppTheme.primary,
                    size: 40,
                  ),
                  children: const [
                    Text('Ứng dụng mua sắm thời trang Daisy Shop.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Daisy Shop • Phiên bản 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.outline,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.outline),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
      ),
      value: value,
      activeThumbColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final ValueChanged<String> onMessage;

  const _ChangePasswordDialog({required this.onMessage});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  late TextEditingController currentPassword;
  late TextEditingController newPassword;

  @override
  void initState() {
    super.initState();
    currentPassword = TextEditingController();
    newPassword = TextEditingController();
  }

  @override
  void dispose() {
    currentPassword.dispose();
    newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currentPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu hiện tại',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu mới',
              prefixIcon: Icon(Icons.password),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (currentPassword.text.isEmpty || newPassword.text.length < 6) {
              widget.onMessage('Mật khẩu mới cần ít nhất 6 ký tự');
              return;
            }
            FocusScope.of(context).unfocus();
            Navigator.pop(context, true);
          },
          child: const Text('Cập nhật'),
        ),
      ],
    );
  }
}
