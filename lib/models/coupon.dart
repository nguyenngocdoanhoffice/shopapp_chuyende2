class Coupon {
  final int id;
  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final bool isActive;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscount,
    required this.isActive,
  });

  factory Coupon.fromMap(Map<String, dynamic> map) {
    return Coupon(
      id: map['id'] as int,
      code: map['code'] as String,
      discountType: map['discount_type'] as String,
      discountValue: (map['discount_value'] as num).toDouble(),
      minOrderAmount: (map['min_order_amount'] as num?)?.toDouble() ?? 0,
      maxDiscount: (map['max_discount'] as num?)?.toDouble(),
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
