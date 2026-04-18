import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../ui/widgets/app_surfaces.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();
  String _paymentMethod = 'cod';
  double _discount = 0;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    try {
      final discount = await orderProvider.applyCoupon(
        code: _couponCtrl.text.trim(),
        subtotal: cartProvider.subtotal,
      );
      setState(() {
        _discount = discount;
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mã giảm giá đã áp dụng: -\$${discount.toStringAsFixed(2)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _checkout() async {
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.shippingAddressRequired)),
      );
      return;
    }

    try {
      await orderProvider.checkout(
        cartProvider: cartProvider,
        shippingAddress: _addressCtrl.text.trim(),
        paymentMethod: _paymentMethod,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.orderPlacedSuccess)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final total = cartProvider.subtotal - _discount + 5;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkoutTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.shippingDetails,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.shippingAddress,
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
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
                    AppStrings.coupon,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _couponCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: AppStrings.couponCode,
                      prefixIcon: const Icon(Icons.discount_outlined),
                      suffixIcon: IconButton(
                        onPressed: _applyCoupon,
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                    ),
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
                    AppStrings.paymentMethod,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: 'cod',
                        icon: Icon(Icons.payments_outlined),
                        label: Text(AppStrings.cod),
                      ),
                      ButtonSegment(
                        value: 'bank_transfer',
                        icon: Icon(Icons.account_balance_outlined),
                        label: Text(AppStrings.bankLabel),
                      ),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (value) => setState(() {
                      _paymentMethod = value.first;
                    }),
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
                    AppStrings.orderSummary,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    label: AppStrings.subtotal,
                    value: '\$${cartProvider.subtotal.toStringAsFixed(2)}',
                  ),
                  _SummaryRow(
                    label: AppStrings.discount,
                    value: '-\$${_discount.toStringAsFixed(2)}',
                  ),
                  const _SummaryRow(
                    label: AppStrings.shippingFee,
                    value: '\$5.00',
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.total,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      PriceText(total),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _checkout,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(AppStrings.placeOrder),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}
