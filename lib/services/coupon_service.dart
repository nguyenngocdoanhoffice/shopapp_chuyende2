import '../models/coupon.dart';
import '../supabase_client.dart';

class CouponService {
  Future<Coupon?> validateCoupon(String code) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final data = await supabase
        .from('coupons')
        .select()
        .eq('code', code.toUpperCase())
        .eq('is_active', true)
        .lte('start_at', now)
        .gte('end_at', now)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return Coupon.fromMap(data);
  }

  Future<List<Coupon>> getCoupons() async {
    final data = await supabase
        .from('coupons')
        .select()
        .order('created_at', ascending: false);
    return data.map((item) => Coupon.fromMap(item)).toList();
  }

  Future<void> createCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    required double minOrderAmount,
    double? maxDiscount,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    await supabase.from('coupons').insert({
      'code': code.toUpperCase(),
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      'max_discount': maxDiscount,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
    });
  }

  Future<void> updateCouponStatus({
    required int id,
    required bool isActive,
  }) async {
    await supabase.from('coupons').update({'is_active': isActive}).eq('id', id);
  }

  Future<void> deleteCoupon(int id) async {
    await supabase.from('coupons').delete().eq('id', id);
  }
}
