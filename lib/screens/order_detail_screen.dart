import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_detail.dart';
import '../providers/admin_provider.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final int? sequence;

  const OrderDetailScreen({super.key, required this.orderId, this.sequence});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetail();
    });
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await context.read<AdminProvider>().getOrderDetail(
        widget.orderId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.sequence != null
        ? 'Chi tiết đơn hàng #${widget.sequence} (ID ${widget.orderId})'
        : 'Chi tiết đơn hàng ID ${widget.orderId}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const AppLoading(message: 'Đang tải chi tiết đơn hàng')
          : _error != null
          ? Center(child: Text(_error!))
          : _detail == null
          ? const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Không tìm thấy đơn hàng',
              subtitle: 'Đơn hàng có thể đã bị xóa hoặc không tồn tại.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin người mua',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _line('Họ tên', _detail!.user?.fullName ?? ''),
                      _line('Email', _detail!.user?.email ?? ''),
                      _line('Số điện thoại', _detail!.user?.phone ?? ''),
                      _line('Địa chỉ', _detail!.shippingAddress),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin đơn hàng',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _line('Trạng thái', _detail!.status),
                      _line('Thanh toán', _detail!.paymentMethod),
                      _line(
                        'Thời gian đặt',
                        _detail!.createdAt != null
                            ? '${_detail!.createdAt!.toLocal()}'
                            : '',
                      ),
                      _line('Tổng tiền', '${_detail!.totalAmount.round()} ₫'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sản phẩm',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._detail!.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(item.productName)),
                              Text('x${item.quantity}'),
                              const SizedBox(width: 12),
                              Text('${item.unitPrice.round()} ₫'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
