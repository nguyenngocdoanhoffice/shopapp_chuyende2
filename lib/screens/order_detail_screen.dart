import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_detail.dart';
import '../providers/admin_provider.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

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
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiet don hang #${widget.orderId}')),
      body: _isLoading
          ? const AppLoading(message: 'Dang tai chi tiet don hang')
          : _error != null
          ? Center(child: Text(_error!))
          : _detail == null
          ? const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Khong tim thay don hang',
              subtitle: 'Don hang co the da bi xoa hoac khong ton tai.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thong tin nguoi mua',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _line('Ho ten', _detail!.user?.fullName ?? ''),
                      _line('Email', _detail!.user?.email ?? ''),
                      _line('So dien thoai', _detail!.user?.phone ?? ''),
                      _line('Dia chi', _detail!.shippingAddress),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thong tin don hang',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _line('Trang thai', _detail!.status),
                      _line('Thanh toan', _detail!.paymentMethod),
                      _line(
                        'Thoi gian dat',
                        _detail!.createdAt?.toLocal().toString() ?? '',
                      ),
                      _line(
                        'Tong tien',
                        '\$${_detail!.totalAmount.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'San pham',
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
                              Text('\$${item.unitPrice.toStringAsFixed(2)}'),
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
