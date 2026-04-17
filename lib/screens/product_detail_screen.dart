import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: product.imageUrl == null || product.imageUrl!.isEmpty
                  ? const Placeholder()
                  : Image.network(product.imageUrl!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(product.category),
            const SizedBox(height: 8),
            Text('\$${product.price.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Text(product.description),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: product.stock <= 0
                  ? null
                  : () async {
                      await context.read<CartProvider>().addItem(product.id);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart')),
                      );
                    },
              child: const Text('Add to cart'),
            ),
          ],
        ),
      ),
    );
  }
}
