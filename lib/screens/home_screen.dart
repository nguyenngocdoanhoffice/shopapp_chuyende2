import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá thiết bị'),
        actions: [
          IconButton(
            tooltip: AppStrings.cart,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
            },
            icon: Badge(
              isLabelVisible: cartProvider.totalItems > 0,
              label: Text('${cartProvider.totalItems}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primaryContainer],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    authProvider.userProfile?.fullName.isNotEmpty == true
                        ? authProvider.userProfile!.fullName
                        : 'Mobile Device Shop',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.userProfile?.email ?? '',
                    style: TextStyle(color: scheme.onPrimary),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text(AppStrings.profile),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text(AppStrings.orderHistory),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
            if (authProvider.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text(AppStrings.adminDashboard),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(AppStrings.logout),
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
            AppSectionCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText:
                            'Tìm kiếm điện thoại, máy tính bảng, phụ kiện...',
                        border: InputBorder.none,
                        filled: false,
                        suffixIcon: IconButton(
                          onPressed: () => productProvider.setSearch(
                            _searchCtrl.text.trim(),
                          ),
                          icon: const Icon(Icons.search),
                        ),
                      ),
                      onSubmitted: (value) => productProvider.setSearch(value),
                    ),
                  ),
                ],
              ),
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
                  final isSelected =
                      category == productProvider.selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => productProvider.setCategory(category),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (productProvider.error != null)
              AppErrorBanner(message: productProvider.error!),
            Expanded(
              child: productProvider.isLoading
                  ? const AppLoading(message: 'Đang tải sản phẩm')
                  : productProvider.products.isEmpty
                  ? AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: AppStrings.noProducts,
                      subtitle: 'Thử từ khóa hoặc danh mục khác.',
                      action: OutlinedButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          productProvider
                            ..setSearch('')
                            ..setCategory('All');
                        },
                        child: const Text('Đặt lại bộ lọc'),
                      ),
                    )
                  : GridView.builder(
                      itemCount: productProvider.products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.66,
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
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: AppSectionCard(
        padding: const EdgeInsets.all(10),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: product.imageUrl == null || product.imageUrl!.isEmpty
                        ? Container(
                            color: scheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                            ),
                          )
                        : Image.network(product.imageUrl!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                product.category,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              PriceText(product.price),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: product.stock <= 0
                      ? null
                      : () async {
                          await context.read<CartProvider>().addItem(
                            product.id,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã thêm vào giỏ hàng'),
                            ),
                          );
                        },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Thêm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
