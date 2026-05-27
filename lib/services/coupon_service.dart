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

    // Check applicable users if set on the coupon
    final currentUserId = supabase.auth.currentUser?.id;
    final allowed = (data['applicable_user_ids'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList();

    if (allowed != null && allowed.isNotEmpty) {
      if (currentUserId == null || !allowed.contains(currentUserId)) {
        return null;
      }
    }

    return Coupon.fromMap(data);
  }

  Future<List<Coupon>> getCoupons() async {
    final data =
        await supabase
                .from('coupons')
                .select()
                .order('created_at', ascending: false)
            as List<dynamic>;
    return data
        .map((item) => Coupon.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    required double minOrderAmount,
    double? maxDiscount,
    required DateTime startAt,
    required DateTime endAt,
    List<String>? applicableUserIds,
  }) async {
    final payload = <String, dynamic>{
      'code': code.toUpperCase(),
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      'max_discount': maxDiscount,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
    };
    if (applicableUserIds != null) {
      payload['applicable_user_ids'] = applicableUserIds;
    }

    await supabase.from('coupons').insert(payload);
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
