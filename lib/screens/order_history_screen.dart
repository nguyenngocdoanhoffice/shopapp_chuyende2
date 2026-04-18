import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/order_provider.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.orderHistory)),
      body: provider.isLoading
          ? const AppLoading(message: AppStrings.loadingOrders)
          : provider.orders.isEmpty
          ? const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.noOrders,
              subtitle: AppStrings.noOrdersSubtitle,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.orders.length,
              itemBuilder: (context, index) {
                final order = provider.orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSectionCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '${AppStrings.orderId}${order.id}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Chip(
                              label: Text(order.status.toUpperCase()),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: AppStrings.items,
                          value: '${order.items.length}',
                        ),
                        _InfoRow(
                          label: AppStrings.paymentLabel,
                          value: order.paymentMethod,
                        ),
                        _InfoRow(
                          label: AppStrings.shippingLabel,
                          value: order.shippingAddress,
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.total,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            PriceText(order.totalAmount),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
