import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

Future<bool> showAdminConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận',
  String cancelLabel = 'Hủy',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(message, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppTheme.error : AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class AdminStatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  const AdminStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  const AdminStatePanel.loading({super.key})
      : icon = Icons.hourglass_empty,
        title = 'Đang tải dữ liệu',
        message = 'Vui lòng chờ trong giây lát.',
        actionLabel = null,
        onAction = null,
        loading = true;

  const AdminStatePanel.empty({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'Chưa có dữ liệu',
    this.message = 'Kết quả sẽ xuất hiện tại đây khi có dữ liệu phù hợp.',
    this.actionLabel,
    this.onAction,
  }) : loading = false;

  const AdminStatePanel.error({
    super.key,
    this.icon = Icons.error_outline,
    this.title = 'Không tải được dữ liệu',
    this.message = 'Có lỗi xảy ra. Hãy thử tải lại hoặc kiểm tra kết nối.',
    this.actionLabel = 'Thử lại',
    this.onAction,
  }) : loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class AdminStateSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const AdminStateSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const states = [
      ('normal', 'Dữ liệu'),
      ('loading', 'Loading'),
      ('empty', 'Empty'),
      ('error', 'Error'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final state in states)
          ChoiceChip(
            label: Text(state.$2),
            selected: value == state.$1,
            showCheckmark: false,
            selectedColor: AppTheme.primaryContainer,
            backgroundColor: AppTheme.surfaceContainerLow,
            labelStyle: TextStyle(
              color: value == state.$1 ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => onChanged(state.$1),
          ),
      ],
    );
  }
}
