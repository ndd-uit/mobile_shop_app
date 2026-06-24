import 'supabase_client.dart';
import '../models/customer_profile.dart';
import '../models/shipping_address.dart';
import 'auth_service.dart';

class ProfileService {
  /// Lấy profile của user hiện tại kèm danh sách địa chỉ.
  static Future<CustomerProfile?> fetchCurrent() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return null;

    final profileRow = await supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (profileRow == null) return null;

    final addressRows = await supabase
        .from('shipping_addresses')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: true);

    final addresses = (addressRows as List)
        .cast<Map<String, dynamic>>()
        .map((row) => ShippingAddress(
              id: row['id'] as String,
              label: row['label'] as String,
              address: row['address'] as String,
            ))
        .toList();

    return CustomerProfile(
      name: profileRow['name'] as String,
      phoneNumber: profileRow['phone_number'] as String,
      avatarPath: profileRow['avatar_url'] as String?,
      addresses: addresses,
      defaultAddressId: profileRow['default_address_id'] as String?,
    );
  }

  /// Lưu profile (name, phone, avatar_url, default_address_id) lên Supabase.
  static Future<void> save(CustomerProfile profile) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await supabase.from('profiles').update({
      'name': profile.name,
      'phone_number': profile.phoneNumber,
      'avatar_url': profile.avatarPath,
      'default_address_id': profile.defaultAddressId,
    }).eq('id', uid);
  }

  /// Thêm địa chỉ mới vào DB, trả về địa chỉ với id được tạo.
  static Future<ShippingAddress> addAddress({
    required String uid,
    required String label,
    required String address,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    await supabase.from('shipping_addresses').insert({
      'id': id,
      'user_id': uid,
      'label': label,
      'address': address,
    });

    return ShippingAddress(id: id, label: label, address: address);
  }

  /// Cập nhật label và address của một địa chỉ.
  static Future<void> updateAddress(ShippingAddress address) async {
    await supabase
        .from('shipping_addresses')
        .update({'label': address.label, 'address': address.address})
        .eq('id', address.id);
  }

  /// Xóa địa chỉ.
  static Future<void> deleteAddress(String id) async {
    await supabase.from('shipping_addresses').delete().eq('id', id);
  }
}
