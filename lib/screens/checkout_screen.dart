import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';

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
          content: Text('Coupon applied: -\$${discount.toStringAsFixed(2)}'),
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
        const SnackBar(content: Text('Shipping address is required')),
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
        const SnackBar(content: Text('Order placed successfully')),
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
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Shipping address'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _couponCtrl,
              decoration: InputDecoration(
                labelText: 'Coupon code',
                suffixIcon: IconButton(
                  onPressed: _applyCoupon,
                  icon: const Icon(Icons.check),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: const [
                DropdownMenuItem(value: 'cod', child: Text('Cash on Delivery')),
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text('Bank Transfer'),
                ),
              ],
              onChanged: (value) => setState(() {
                _paymentMethod = value ?? 'cod';
              }),
              decoration: const InputDecoration(labelText: 'Payment method'),
            ),
            const SizedBox(height: 24),
            Text('Subtotal: \$${cartProvider.subtotal.toStringAsFixed(2)}'),
            Text('Discount: -\$${_discount.toStringAsFixed(2)}'),
            const Text('Shipping fee: \$5.00'),
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _checkout,
              child: const Text('Place order'),
            ),
          ],
        ),
      ),
    );
  }
}
