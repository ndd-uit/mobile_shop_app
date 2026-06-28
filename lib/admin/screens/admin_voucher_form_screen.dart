import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/admin_shell.dart';

class AdminVoucherFormScreen extends StatefulWidget {
  const AdminVoucherFormScreen({super.key});

  @override
  State<AdminVoucherFormScreen> createState() => _AdminVoucherFormScreenState();
}

class _AdminVoucherFormScreenState extends State<AdminVoucherFormScreen> {
  bool isActive = true;
  String discountType = 'percentage';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final isEdit = args is Map && args['mode'] == 'edit';
    final code = args is Map ? args['code'] as String? : null;

    return AdminShell(
      currentSection: AdminSection.vouchers,
      showSearch: false,
      breadcrumb: _VoucherBreadcrumb(isEdit: isEdit),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PageHeader(isEdit: isEdit),
            const SizedBox(height: 28),
            _FormPanel(
              isEdit: isEdit,
              code: code,
              discountType: discountType,
              isActive: isActive,
              onDiscountTypeChanged: (value) => setState(() => discountType = value),
              onActiveChanged: (value) => setState(() => isActive = value),
              onCancel: _goBack,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    Navigator.pushReplacementNamed(context, '/admin/vouchers');
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tạo voucher sẽ được nối Supabase ở bước tiếp theo'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _VoucherBreadcrumb extends StatelessWidget {
  final bool isEdit;

  const _VoucherBreadcrumb({required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/admin/vouchers'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
          ),
          child: const Text('Vouchers'),
        ),
        const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant, size: 18),
        const SizedBox(width: 4),
        Text(
          isEdit ? 'Sửa voucher' : 'Tạo mới',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  final bool isEdit;

  const _PageHeader({required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Text(
      isEdit ? 'Sửa Voucher' : 'Tạo Voucher Mới',
      style: const TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final bool isEdit;
  final String? code;
  final String discountType;
  final bool isActive;
  final ValueChanged<String> onDiscountTypeChanged;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _FormPanel({
    required this.isEdit,
    this.code,
    required this.discountType,
    required this.isActive,
    required this.onDiscountTypeChanged,
    required this.onActiveChanged,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              icon: Icons.info_outline,
              title: 'Thông tin cơ bản',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final twoCols = constraints.maxWidth >= 640;
                  final fields = [
                    _VoucherCodeField(initialCode: code),
                    _DiscountTypeField(
                      value: discountType,
                      onChanged: onDiscountTypeChanged,
                    ),
                    _DiscountValueField(discountType: discountType),
                  ];
                  if (!twoCols) {
                    return Column(
                      children: [
                        fields[0],
                        const SizedBox(height: 20),
                        fields[1],
                        const SizedBox(height: 20),
                        fields[2],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: fields[0]),
                          const SizedBox(width: 24),
                          Expanded(child: fields[1]),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: fields[2]),
                          const SizedBox(width: 24),
                          const Spacer(),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            const _Section(
              icon: Icons.rule_outlined,
              title: 'Điều kiện áp dụng',
              child: _ConstraintFields(),
            ),
            const SizedBox(height: 32),
            _ActiveStatusSection(isActive: isActive, onChanged: onActiveChanged),
            const SizedBox(height: 32),
            const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
            const SizedBox(height: 24),
            _FormActions(isEdit: isEdit, onCancel: onCancel, onSubmit: onSubmit),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

class _VoucherCodeField extends StatelessWidget {
  final String? initialCode;

  const _VoucherCodeField({this.initialCode});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Mã voucher', required: true),
        TextField(
          controller: initialCode == null ? null : TextEditingController(text: initialCode),
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'VD: SUMMER2024'),
        ),
        const SizedBox(height: 6),
        const Text(
          'Khách hàng sẽ nhập mã này khi thanh toán.',
          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

class _DiscountTypeField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DiscountTypeField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Loại giảm giá'),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          items: const [
            DropdownMenuItem(value: 'percentage', child: Text('Phần trăm (%)')),
            DropdownMenuItem(value: 'fixed', child: Text('Số tiền cố định (VNĐ)')),
            DropdownMenuItem(value: 'freeship', child: Text('Miễn phí vận chuyển')),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _DiscountValueField extends StatelessWidget {
  final String discountType;

  const _DiscountValueField({required this.discountType});

  @override
  Widget build(BuildContext context) {
    final suffix = switch (discountType) {
      'percentage' => '%',
      'fixed' => 'đ',
      _ => '',
    };
    final hint = discountType == 'freeship' ? '0' : '0';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Giá trị giảm', required: true),
        TextField(
          enabled: discountType != 'freeship',
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix.isEmpty ? null : suffix,
          ),
        ),
      ],
    );
  }
}

class _ConstraintFields extends StatelessWidget {
  const _ConstraintFields();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 640;
        if (!twoCols) {
          return const Column(
            children: [
              _ExpiryDateField(),
              SizedBox(height: 20),
              _UsageLimitField(),
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ExpiryDateField()),
            SizedBox(width: 24),
            Expanded(child: _UsageLimitField()),
          ],
        );
      },
    );
  }
}

class _ExpiryDateField extends StatelessWidget {
  const _ExpiryDateField();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('Ngày hết hạn'),
        TextField(
          decoration: InputDecoration(hintText: 'dd/mm/yyyy'),
        ),
      ],
    );
  }
}

class _UsageLimitField extends StatelessWidget {
  const _UsageLimitField();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('Giới hạn lượt dùng'),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Không giới hạn'),
        ),
      ],
    );
  }
}

class _ActiveStatusSection extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _ActiveStatusSection({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        border: Border.all(color: AppTheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạng thái kích hoạt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Voucher có thể sử dụng ngay sau khi tạo.',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeThumbColor: AppTheme.onPrimary,
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.surfaceContainerHighest,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FormActions extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _FormActions({
    required this.isEdit,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final cancel = OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Hủy'),
        );
        final submit = FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(isEdit ? 'Cập nhật voucher' : 'Tạo voucher'),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cancel,
              const SizedBox(height: 12),
              submit,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            cancel,
            const SizedBox(width: 16),
            submit,
          ],
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: text),
            if (required) const TextSpan(text: ' *', style: TextStyle(color: AppTheme.error)),
          ],
        ),
      ),
    );
  }
}
