class Coupon {
  final int id;
  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final bool isActive;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<String>? applicableUserIds;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscount,
    required this.isActive,
    this.startAt,
    this.endAt,
    this.applicableUserIds,
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
      startAt: map['start_at'] == null
          ? null
          : DateTime.parse(map['start_at'] as String).toLocal(),
      endAt: map['end_at'] == null
          ? null
          : DateTime.parse(map['end_at'] as String).toLocal(),
      applicableUserIds: (map['applicable_user_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}
