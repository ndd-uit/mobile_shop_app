import 'shipping_address.dart';

class CustomerProfile {
  final String name;
  final String phoneNumber;
  final String? avatarPath;
  final List<ShippingAddress> addresses;
  final String? defaultAddressId;

  const CustomerProfile({
    required this.name,
    required this.phoneNumber,
    this.avatarPath,
    this.addresses = const [],
    this.defaultAddressId,
  });

  ShippingAddress? get defaultAddress {
    if (addresses.isEmpty) return null;
    for (final address in addresses) {
      if (address.id == defaultAddressId) return address;
    }
    return addresses.first;
  }

  bool get hasCompleteShippingInfo {
    return name.trim().isNotEmpty &&
        phoneNumber.trim().isNotEmpty &&
        defaultAddress != null;
  }

  CustomerProfile copyWith({
    String? name,
    String? phoneNumber,
    String? avatarPath,
    List<ShippingAddress>? addresses,
    String? defaultAddressId,
  }) {
    return CustomerProfile(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarPath: avatarPath ?? this.avatarPath,
      addresses: addresses ?? this.addresses,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
    );
  }
}
