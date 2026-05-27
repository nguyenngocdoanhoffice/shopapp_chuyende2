import 'package:flutter/material.dart';

import '../ui/widgets/app_surfaces.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liên hệ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin liên hệ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                Text('Email: support@shopapp.vn'),
                SizedBox(height: 6),
                Text('Điện thoại: 0900 123 456'),
                SizedBox(height: 6),
                Text('Địa chỉ: Hà Nội '),
              ],
            ),
          ),
          SizedBox(height: 12),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hỗ trợ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text('• Hỗ trợ đơn hàng và thanh toán'),
                Text('• Tư vấn sản phẩm'),
                Text('• Xử lý mã giảm giá và tài khoản'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
