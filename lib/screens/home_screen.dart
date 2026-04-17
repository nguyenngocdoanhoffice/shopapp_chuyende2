import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'admin_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = context.read<ProductProvider>();
      final cartProvider = context.read<CartProvider>();
      await productProvider.loadInitialData();
      await cartProvider.loadCart();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Device Shop'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: Badge(
              label: Text('${cartProvider.totalItems}'),
              child: const Icon(Icons.shopping_cart),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Menu')),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Order history'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
            if (authProvider.isAdmin)
              ListTile(
                title: const Text('Admin dashboard'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
              ),
            ListTile(
              title: const Text('Logout'),
              onTap: () async {
                await authProvider.logout();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search products',
                suffixIcon: IconButton(
                  onPressed: () =>
                      productProvider.setSearch(_searchCtrl.text.trim()),
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (value) => productProvider.setSearch(value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: productProvider.categories.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = productProvider.categories[index];
                  final isSelected = category == productProvider.selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => productProvider.setCategory(category),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      itemCount: productProvider.products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (context, index) {
                        final product = productProvider.products[index];
                        return _ProductCard(product: product);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: product.imageUrl == null || product.imageUrl!.isEmpty
                      ? const Placeholder()
                      : Image.network(product.imageUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
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
                  icon: const Icon(Icons.add_shopping_cart),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
