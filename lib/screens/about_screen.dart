import 'package:flutter/material.dart';

import '../ui/widgets/app_surfaces.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shopapp',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                Text(
                  'Shopapp là ứng dụng mua sắm thiết bị với giao diện đơn giản, có giỏ hàng, lịch sử đơn hàng, mã giảm giá và khu vực quản trị.',
                ),
                SizedBox(height: 12),
                Text(
                  'Mục tiêu của ứng dụng là giúp người dùng tìm sản phẩm nhanh, đặt hàng thuận tiện và theo dõi đơn hàng rõ ràng.',
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tính năng chính',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text('• Tìm kiếm và lọc sản phẩm'),
                Text('• Giỏ hàng và thanh toán'),
                Text('• Lịch sử đơn hàng'),
                Text('• Mã giảm giá'),
                Text('• Quản trị sản phẩm, đơn hàng, báo cáo'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
