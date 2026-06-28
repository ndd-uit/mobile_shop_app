import 'package:flutter/material.dart';

import '../../services/voucher_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/admin_feedback.dart';
import '../widgets/admin_shell.dart';

class AdminVouchersScreen extends StatefulWidget {
  const AdminVouchersScreen({super.key});

  @override
  State<AdminVouchersScreen> createState() => _AdminVouchersScreenState();
}

class _AdminVouchersScreenState extends State<AdminVouchersScreen> {
  String query = '';
  String status = 'Trạng thái';
  late Future<List<_Voucher>> vouchersFuture;

  @override
  void initState() {
    super.initState();
    vouchersFuture = _loadVouchers();
  }

  Future<List<_Voucher>> _loadVouchers() async {
    final vouchers = await VoucherService.fetchAdminAll();
    return vouchers.map(_Voucher.fromAdminVoucher).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_Voucher>>(
      future: vouchersFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final allVouchers = snapshot.data ?? const <_Voucher>[];
        final vouchers = allVouchers.where((voucher) {
          final matchesQuery = query.isEmpty ||
              voucher.code.toLowerCase().contains(query.toLowerCase());
          final matchesStatus = status == 'Trạng thái' ||
              (status == 'Đang bật' && voucher.active) ||
              (status == 'Đang tắt' && !voucher.active);
          return matchesQuery && matchesStatus;
        }).toList();

        return AdminShell(
          currentSection: AdminSection.vouchers,
          onSearchChanged: (value) => setState(() => query = value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PageHeader(onCreate: _showCreateVoucher),
              const SizedBox(height: 32),
              _VoucherFilters(
                status: status,
                onQueryChanged: (value) => setState(() => query = value),
                onStatusChanged: (value) => setState(() => status = value),
              ),
              const SizedBox(height: 24),
              _VoucherStatsGrid(vouchers: allVouchers),
              const SizedBox(height: 32),
              if (loading)
                const AdminStatePanel.loading()
              else if (snapshot.hasError)
                AdminStatePanel.error(onAction: _refreshVouchers)
              else if (vouchers.isEmpty)
                AdminStatePanel.empty(
                  title: 'Không tìm thấy voucher',
                  message: 'Thử đổi mã tìm kiếm hoặc trạng thái voucher.',
                  actionLabel: 'Xóa bộ lọc',
                  onAction: _clearFilters,
                )
              else
                _VoucherTable(
                  vouchers: vouchers,
                  onEdit: _editVoucher,
                  onToggle: _toggleVoucher,
                ),
            ],
          ),
        );
      },
    );
  }

  void _refreshVouchers() {
    setState(() => vouchersFuture = _loadVouchers());
  }

  void _showCreateVoucher() {
    Navigator.pushNamed(context, '/admin/vouchers/form');
  }

  void _clearFilters() {
    setState(() {
      query = '';
      status = 'Trạng thái';
    });
  }

  void _editVoucher(_Voucher voucher) {
    Navigator.pushNamed(
      context,
      '/admin/vouchers/form',
      arguments: {'mode': 'edit', 'code': voucher.code},
    );
  }

  Future<void> _toggleVoucher(_Voucher voucher) async {
    final confirmed = await showAdminConfirmDialog(
      context: context,
      title: voucher.active ? 'Tắt voucher?' : 'Bật voucher?',
      message: voucher.active
          ? 'Khách hàng sẽ không thể sử dụng mã ${voucher.code}.'
          : 'Khách hàng có thể sử dụng lại mã ${voucher.code}.',
      confirmLabel: voucher.active ? 'Tắt voucher' : 'Bật voucher',
    );
    if (!confirmed || !mounted) return;
    try {
      await VoucherService.setActive(
        code: voucher.code,
        isActive: !voucher.active,
      );
      if (!mounted) return;
      _refreshVouchers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không cập nhật được voucher: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(voucher.active ? 'Đã tắt ${voucher.code}' : 'Đã bật ${voucher.code}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _VoucherFilters extends StatelessWidget {
  final String status;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;

  const _VoucherFilters({
    required this.status,
    required this.onQueryChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            onChanged: onQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Tìm mã voucher...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            items: const [
              DropdownMenuItem(value: 'Trạng thái', child: Text('Trạng thái')),
              DropdownMenuItem(value: 'Đang bật', child: Text('Đang bật')),
              DropdownMenuItem(value: 'Đang tắt', child: Text('Đang tắt')),
            ],
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  final VoidCallback onCreate;

  const _PageHeader({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final title = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh sách Voucher',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Quản lý các chương trình khuyến mãi và mã giảm giá cho cửa hàng.',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ],
        );
        final button = FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tạo voucher'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: button),
            ],
          );
        }
        return Row(children: [Expanded(child: title), button]);
      },
    );
  }
}

class _VoucherStatsGrid extends StatelessWidget {
  final List<_Voucher> vouchers;

  const _VoucherStatsGrid({required this.vouchers});

  @override
  Widget build(BuildContext context) {
    final activeCount = vouchers.where((voucher) => voucher.active).length;
    final usedCount = vouchers.fold<int>(
      0,
      (total, voucher) => total + voucher.usedCount,
    );
    final expiredCount = vouchers.where((voucher) => voucher.expired).length;
    final newThisMonth = vouchers.where((voucher) {
      final now = DateTime.now();
      return voucher.startsAt.year == now.year && voucher.startsAt.month == now.month;
    }).length;
    final stats = [
      _VoucherStat(
        'Tổng voucher',
        _formatNumber(vouchers.length),
        '+$newThisMonth mới tháng này',
        AppTheme.onSurface,
        null,
      ),
      _VoucherStat(
        'Đang hoạt động',
        _formatNumber(activeCount),
        null,
        AppTheme.primary,
        Icons.check_circle,
      ),
      _VoucherStat(
        'Đã sử dụng',
        _formatNumber(usedCount),
        'Lượt dùng',
        AppTheme.onSurface,
        null,
      ),
      _VoucherStat(
        'Hết hạn',
        _formatNumber(expiredCount),
        null,
        AppTheme.error,
        Icons.history,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 920 ? 4 : (width >= 560 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _VoucherStatCard(stat: stats[index]),
        );
      },
    );
  }
}

class _VoucherStatCard extends StatelessWidget {
  final _VoucherStat stat;

  const _VoucherStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border.all(color: AppTheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stat.label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  stat.value,
                  style: TextStyle(
                    color: stat.valueColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (stat.trailingText != null)
                Flexible(
                  child: Text(
                    stat.trailingText!,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (stat.icon != null)
                Icon(stat.icon, color: stat.valueColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoucherTable extends StatelessWidget {
  final List<_Voucher> vouchers;
  final ValueChanged<_Voucher> onEdit;
  final ValueChanged<_Voucher> onToggle;

  const _VoucherTable({
    required this.vouchers,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [
                    for (final voucher in vouchers)
                      _VoucherMobileCard(
                        voucher: voucher,
                        onEdit: () => onEdit(voucher),
                        onToggle: () => onToggle(voucher),
                      ),
                  ],
                );
              }
              return Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.35),
                  1: FlexColumnWidth(1.0),
                  2: FlexColumnWidth(1.05),
                  3: FlexColumnWidth(0.7),
                  4: FlexColumnWidth(1.1),
                  5: FlexColumnWidth(0.95),
                  6: FlexColumnWidth(1.0),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh),
                    children: [
                      _HeaderCell('Mã Code'),
                      _HeaderCell('Giá trị giảm'),
                      _HeaderCell('Ngày hết hạn'),
                      _HeaderCell('Giới hạn'),
                      _HeaderCell('Đã dùng'),
                      _HeaderCell('Trạng thái'),
                      _HeaderCell('Hành động', alignCenter: true),
                    ],
                  ),
                  for (final voucher in vouchers) _voucherRow(voucher),
                ],
              );
            },
          ),
          _Pagination(total: vouchers.length),
        ],
      ),
    );
  }

  TableRow _voucherRow(_Voucher voucher) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Align(alignment: Alignment.centerLeft, child: _CodeBadge(voucher: voucher)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(voucher.value, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (voucher.note != null) ...[
                const SizedBox(height: 2),
                Text(
                  voucher.note!,
                  style: const TextStyle(color: AppTheme.secondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        _BodyCell(voucher.expiresAt),
        _BodyCell(voucher.limit),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: _UsageMeter(voucher: voucher),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Align(alignment: Alignment.centerLeft, child: _StatusBadge(active: voucher.active)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => onEdit(voucher),
                tooltip: 'Sửa voucher',
                icon: const Icon(Icons.edit_outlined),
                color: AppTheme.secondary,
              ),
              Switch(
                value: voucher.active,
                activeThumbColor: AppTheme.onPrimary,
                activeTrackColor: AppTheme.primary,
                inactiveTrackColor: AppTheme.secondaryContainer,
                onChanged: (_) => onToggle(voucher),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VoucherMobileCard extends StatelessWidget {
  final _Voucher voucher;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _VoucherMobileCard({
    required this.voucher,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _CodeBadge(voucher: voucher)),
              _StatusBadge(active: voucher.active),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _MobileMeta(label: 'Giảm', value: voucher.value)),
              Expanded(child: _MobileMeta(label: 'Hết hạn', value: voucher.expiresAt)),
              Expanded(child: _MobileMeta(label: 'Giới hạn', value: voucher.limit)),
            ],
          ),
          const SizedBox(height: 14),
          _UsageMeter(voucher: voucher),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
              Switch(value: voucher.active, onChanged: (_) => onToggle()),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileMeta extends StatelessWidget {
  final String label;
  final String value;

  const _MobileMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.secondary, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final _Voucher voucher;

  const _CodeBadge({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final active = voucher.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryFixed : AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        voucher.code,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: active ? AppTheme.primary : AppTheme.onSurface,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UsageMeter extends StatelessWidget {
  final _Voucher voucher;

  const _UsageMeter({required this.voucher});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(voucher.used, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: voucher.usedPercent,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryContainer : AppTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppTheme.primary : AppTheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Bật' : 'Tắt',
            style: TextStyle(
              color: active ? AppTheme.onPrimaryContainer : AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool alignCenter;

  const _HeaderCell(this.text, {this.alignCenter = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        textAlign: alignCenter ? TextAlign.center : TextAlign.left,
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

  const _BodyCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int total;

  const _Pagination({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final text = Text(
            total == 0
                ? 'Không có voucher'
                : 'Hiển thị 1-$total trên $total vouchers',
            style: const TextStyle(color: AppTheme.secondary, fontSize: 13),
          );
          final pages = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageButton(label: 'Trước', disabled: true, onPressed: () {}),
              const SizedBox(width: 8),
              _PageButton(label: '1', selected: true, onPressed: () {}),
              const SizedBox(width: 8),
              _PageButton(label: '2', onPressed: () {}),
              const SizedBox(width: 8),
              _PageButton(label: '3', onPressed: () {}),
              const SizedBox(width: 8),
              _PageButton(label: 'Sau', onPressed: () {}),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 12), pages],
            );
          }
          return Row(children: [Expanded(child: text), pages]);
        },
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onPressed;

  const _PageButton({
    required this.label,
    this.selected = false,
    this.disabled = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? AppTheme.primary : null,
          foregroundColor: selected ? AppTheme.onPrimary : AppTheme.onSurface,
          side: BorderSide(color: selected ? AppTheme.primary : AppTheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _VoucherFormDialog extends StatefulWidget {
  const _VoucherFormDialog();

  @override
  State<_VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<_VoucherFormDialog> {
  bool active = true;
  String discountType = 'Giảm theo %';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tạo voucher mới',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FieldLabel('Mã Voucher'),
                      const TextField(
                        decoration: InputDecoration(hintText: 'Ví dụ: DAISYNEW'),
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoCols = constraints.maxWidth >= 420;
                          final fields = [
                            _DiscountTypeField(
                              value: discountType,
                              onChanged: (value) => setState(() => discountType = value),
                            ),
                            const _ValueField(),
                          ];
                          if (!twoCols) {
                            return Column(
                              children: [
                                fields[0],
                                const SizedBox(height: 16),
                                fields[1],
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: fields[0]),
                              const SizedBox(width: 16),
                              Expanded(child: fields[1]),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoCols = constraints.maxWidth >= 420;
                          if (!twoCols) {
                            return const Column(
                              children: [
                                _ExpiryDateField(),
                                SizedBox(height: 16),
                                _UsageLimitField(),
                              ],
                            );
                          }
                          return const Row(
                            children: [
                              Expanded(child: _ExpiryDateField()),
                              SizedBox(width: 16),
                              Expanded(child: _UsageLimitField()),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          border: Border.all(color: AppTheme.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kích hoạt ngay', style: TextStyle(fontWeight: FontWeight.w700)),
                                  SizedBox(height: 3),
                                  Text(
                                    'Voucher sẽ có hiệu lực ngay khi tạo thành công',
                                    style: TextStyle(color: AppTheme.secondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: active,
                              activeThumbColor: AppTheme.onPrimary,
                              activeTrackColor: AppTheme.primary,
                              onChanged: (value) => setState(() => active = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                side: const BorderSide(color: AppTheme.outlineVariant),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Hủy bỏ'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Lưu Voucher'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
          items: const [
            DropdownMenuItem(value: 'Giảm theo %', child: Text('Giảm theo %')),
            DropdownMenuItem(value: 'Số tiền cố định', child: Text('Số tiền cố định')),
            DropdownMenuItem(value: 'Miễn phí vận chuyển', child: Text('Miễn phí vận chuyển')),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _ValueField extends StatelessWidget {
  const _ValueField();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('Giá trị'),
        TextField(decoration: InputDecoration(hintText: '20% hoặc 100,000đ')),
      ],
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
          decoration: InputDecoration(
            hintText: 'dd/mm/yyyy',
            prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
          ),
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
        _FieldLabel('Giới hạn sử dụng'),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Nhập số lượt'),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Voucher {
  final String code;
  final String value;
  final String? note;
  final String expiresAt;
  final String limit;
  final String used;
  final int usedCount;
  final double usedPercent;
  final bool active;
  final bool expired;
  final DateTime startsAt;

  const _Voucher({
    required this.code,
    required this.value,
    this.note,
    required this.expiresAt,
    required this.limit,
    required this.used,
    required this.usedCount,
    required this.usedPercent,
    required this.active,
    required this.expired,
    required this.startsAt,
  });

  factory _Voucher.fromAdminVoucher(AdminVoucher voucher) {
    final usedPercent = voucher.usageLimit == null || voucher.usageLimit == 0
        ? 0.0
        : (voucher.usedCount / voucher.usageLimit!).clamp(0.0, 1.0);
    return _Voucher(
      code: voucher.code,
      value: _discountLabel(voucher),
      note: _noteLabel(voucher),
      expiresAt: voucher.expiresAt == null
          ? 'Không hạn'
          : _formatDate(voucher.expiresAt!),
      limit: voucher.usageLimit?.toString() ?? '∞',
      used: voucher.usedCount.toString(),
      usedCount: voucher.usedCount,
      usedPercent: usedPercent,
      active: voucher.isActive,
      expired: voucher.expiresAt != null && voucher.expiresAt!.isBefore(DateTime.now()),
      startsAt: voucher.startsAt,
    );
  }

  static String _discountLabel(AdminVoucher voucher) => switch (voucher.discountType) {
        'percent' => '${voucher.discountValue}%',
        'fixed' => _formatMoney(voucher.discountValue),
        'shipping' => 'Free Ship',
        _ => voucher.discountValue.toString(),
      };

  static String? _noteLabel(AdminVoucher voucher) {
    final notes = <String>[];
    if (voucher.maxDiscount != null) {
      notes.add('Tối đa ${_formatMoney(voucher.maxDiscount!)}');
    }
    if (voucher.minimumOrder > 0) {
      notes.add('Tối thiểu ${_formatMoney(voucher.minimumOrder)}');
    }
    return notes.isEmpty ? null : notes.join(' • ');
  }

  static String _formatMoney(int value) {
    return '${value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}đ';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _VoucherStat {
  final String label;
  final String value;
  final String? trailingText;
  final Color valueColor;
  final IconData? icon;

  const _VoucherStat(this.label, this.value, this.trailingText, this.valueColor, this.icon);
}

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.surface,
    border: Border.all(color: AppTheme.outlineVariant),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
