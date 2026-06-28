import 'supabase_client.dart';

class VoucherResult {
  final String code;
  final int discount;

  const VoucherResult({required this.code, required this.discount});
}

class VoucherService {
  static Future<List<AdminVoucher>> fetchAdminAll() async {
    final rows = await supabase
        .from('vouchers')
        .select()
        .order('starts_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(AdminVoucher.fromRow)
        .toList();
  }

  static Future<void> setActive({
    required String code,
    required bool isActive,
  }) async {
    await supabase
        .from('vouchers')
        .update({'is_active': isActive})
        .eq('code', code);
  }

  static Future<VoucherResult> validate({
    required String code,
    required int subtotal,
    required int shippingFee,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) throw Exception('Vui lòng nhập mã giảm giá');

    final row = await supabase
        .from('vouchers')
        .select()
        .eq('code', normalized)
        .eq('is_active', true)
        .maybeSingle();

    if (row == null) {
      throw Exception('Mã giảm giá không hợp lệ hoặc đã hết hạn');
    }

    final expiresAt = row['expires_at'] as String?;
    if (expiresAt != null && DateTime.parse(expiresAt).isBefore(DateTime.now())) {
      throw Exception('Mã giảm giá đã hết hạn');
    }

    final minimumOrder = row['minimum_order'] as int? ?? 0;
    if (subtotal < minimumOrder) {
      throw Exception('Đơn hàng chưa đạt giá trị tối thiểu của mã');
    }

    final usageLimit = row['usage_limit'] as int?;
    final usedCount = row['used_count'] as int? ?? 0;
    if (usageLimit != null && usedCount >= usageLimit) {
      throw Exception('Mã giảm giá đã hết lượt sử dụng');
    }

    final discountType = row['discount_type'] as String;
    final discountValue = row['discount_value'] as int? ?? 0;
    final maxDiscount = row['max_discount'] as int?;

    final discount = switch (discountType) {
      'percent' => ((subtotal * discountValue) / 100).round(),
      'fixed' => discountValue,
      'shipping' => shippingFee,
      _ => 0,
    };

    final capped = maxDiscount == null ? discount : discount.clamp(0, maxDiscount);
    final finalDiscount = capped.clamp(0, subtotal + shippingFee);
    if (finalDiscount <= 0) throw Exception('Mã giảm giá không còn giá trị áp dụng');

    return VoucherResult(code: normalized, discount: finalDiscount);
  }
}

class AdminVoucher {
  final String code;
  final String discountType;
  final int discountValue;
  final int? maxDiscount;
  final int minimumOrder;
  final DateTime startsAt;
  final DateTime? expiresAt;
  final int? usageLimit;
  final int usedCount;
  final bool isActive;

  const AdminVoucher({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
    required this.minimumOrder,
    required this.startsAt,
    required this.expiresAt,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
  });

  factory AdminVoucher.fromRow(Map<String, dynamic> row) {
    return AdminVoucher(
      code: row['code'] as String,
      discountType: row['discount_type'] as String,
      discountValue: row['discount_value'] as int? ?? 0,
      maxDiscount: row['max_discount'] as int?,
      minimumOrder: row['minimum_order'] as int? ?? 0,
      startsAt: DateTime.parse(row['starts_at'] as String),
      expiresAt: row['expires_at'] == null
          ? null
          : DateTime.parse(row['expires_at'] as String),
      usageLimit: row['usage_limit'] as int?,
      usedCount: row['used_count'] as int? ?? 0,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}
