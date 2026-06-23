class ShippingAddress {
  final String id;
  final String label;
  final String address;

  const ShippingAddress({
    required this.id,
    required this.label,
    required this.address,
  });

  ShippingAddress copyWith({String? label, String? address}) {
    return ShippingAddress(
      id: id,
      label: label ?? this.label,
      address: address ?? this.address,
    );
  }
}
