import 'package:flutter/material.dart';

import '../models/shop_order.dart';
import '../theme/app_theme.dart';

enum OrderAction { cancel, requestReturn }

Future<ShopOrder?> showOrderActionDialog(
  BuildContext context, {
  required ShopOrder order,
  required OrderAction action,
}) {
  final isCancellation = action == OrderAction.cancel;
  final reasons = isCancellation
      ? const [
          'Muốn thay đổi sản phẩm hoặc địa chỉ',
          'Thời gian giao hàng quá lâu',
          'Không còn nhu cầu mua',
          'Đặt nhầm đơn hàng',
          'Lý do khác',
        ]
      : const [
          'Sản phẩm bị lỗi hoặc hư hỏng',
          'Sản phẩm không đúng mô tả',
          'Giao sai sản phẩm hoặc kích thước',
          'Sản phẩm không vừa',
          'Lý do khác',
        ];

  String? selectedReason;
  return showDialog<ShopOrder>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(isCancellation ? 'Hủy đơn hàng?' : 'Yêu cầu hoàn hàng'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCancellation
                      ? 'Chọn lý do hủy đơn #${order.id}.'
                      : 'Chọn lý do hoàn đơn #${order.id}. Yêu cầu sẽ được cửa hàng xem xét.',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                for (final reason in reasons)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      selectedReason == reason
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selectedReason == reason
                          ? AppTheme.primary
                          : AppTheme.outline,
                    ),
                    title: Text(reason),
                    onTap: () => setDialogState(() => selectedReason = reason),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: selectedReason == null
                ? null
                : () {
                    final now = DateTime.now();
                    Navigator.pop(
                      dialogContext,
                      order.copyWith(
                        status: isCancellation
                            ? OrderStatus.cancelled
                            : OrderStatus.returnRequested,
                        cancellationReason: isCancellation
                            ? selectedReason
                            : null,
                        returnReason: isCancellation ? null : selectedReason,
                        statusUpdatedAt: now,
                      ),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: isCancellation
                  ? AppTheme.error
                  : AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isCancellation ? 'Xác nhận hủy' : 'Gửi yêu cầu'),
          ),
        ],
      ),
    ),
  );
}
