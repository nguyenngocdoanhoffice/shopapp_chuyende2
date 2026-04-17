import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cartProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartProvider.items.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartProvider.items.length,
                        itemBuilder: (context, index) {
                          final item = cartProvider.items[index];
                          final productName = item.product?.name ?? 'Product';

                          return ListTile(
                            title: Text(productName),
                            subtitle: Text(
                              '\$${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => cartProvider.updateItemQty(
                                    item.id,
                                    item.quantity - 1,
                                  ),
                                  icon: const Icon(Icons.remove),
                                ),
                                IconButton(
                                  onPressed: () => cartProvider.updateItemQty(
                                    item.id,
                                    item.quantity + 1,
                                  ),
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  onPressed: () => cartProvider.removeItem(item.id),
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Subtotal: \$${cartProvider.subtotal.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutScreen(),
                                ),
                              );
                            },
                            child: const Text('Checkout'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
