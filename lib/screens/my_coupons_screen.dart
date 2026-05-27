import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coupon.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.userProfile?.id;

    final now = DateTime.now();
    final myCoupons = adminProvider.coupons.where((c) {
      final validDate =
          (c.startAt == null || !c.startAt!.isAfter(now)) &&
          (c.endAt == null || !c.endAt!.isBefore(now));
      final appliesToUser =
          c.applicableUserIds == null ||
          c.applicableUserIds!.isEmpty ||
          (userId != null && c.applicableUserIds!.contains(userId));
      return c.isActive && validDate && appliesToUser;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mã giảm giá của tôi')),
      body: adminProvider.isLoading
          ? const AppLoading(message: 'Đang tải mã giảm giá')
          : myCoupons.isEmpty
          ? const AppEmptyState(
              icon: Icons.discount_outlined,
              title: 'Hiện bạn chưa có mã giảm giá áp dụng.',
              subtitle: 'Hãy quay lại sau hoặc kiểm tra tài khoản của bạn.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: myCoupons.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final coupon = myCoupons[index];
                return _CouponCard(coupon: coupon);
              },
            ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final startText = coupon.startAt != null
        ? '${coupon.startAt!.day}/${coupon.startAt!.month}/${coupon.startAt!.year}'
        : '-';
    final endText = coupon.endAt != null
        ? '${coupon.endAt!.day}/${coupon.endAt!.month}/${coupon.endAt!.year}'
        : '-';

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coupon.code,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Chip(
                label: Text(
                  coupon.discountType == 'percent'
                      ? '${coupon.discountValue}%'
                      : '${coupon.discountValue.round()} ₫',
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Áp dụng từ: $startText'),
          Text('Hết hạn: $endText'),
          Text('Đơn tối thiểu: ${coupon.minOrderAmount.round()} ₫'),
        ],
      ),
    );
  }
}
