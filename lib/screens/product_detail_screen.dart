import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../ui/widgets/app_surfaces.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.productDetail)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl == null || product.imageUrl!.isEmpty
                    ? Container(
                        color: scheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      )
                    : Image.network(product.imageUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Chip(
                        label: Text(product.category),
                        avatar: const Icon(Icons.category_outlined, size: 18),
                      ),
                      const Spacer(),
                      PriceText(product.price),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(product.description),
                  const SizedBox(height: 8),
                  Text(
                    product.stock > 0
                        ? '${AppStrings.stock}${product.stock}'
                        : AppStrings.outOfStock,
                    style: TextStyle(
                      color: product.stock > 0
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: product.stock <= 0
              ? null
              : () async {
                  await context.read<CartProvider>().addItem(product.id);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(AppStrings.addedToCart)),
                  );
                },
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text(AppStrings.addToCart),
        ),
      ),
    );
  }
}
