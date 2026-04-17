import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/admin_provider.dart';
import '../providers/product_provider.dart';
import '../services/storage_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = context.read<ProductProvider>();
      final adminProvider = context.read<AdminProvider>();
      await productProvider.loadInitialData();
      await adminProvider.loadDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openProductDialog({Product? product}) async {
    final productProvider = context.read<ProductProvider>();

    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final categoryCtrl = TextEditingController(text: product?.category ?? 'Phone');
    final priceCtrl = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    final stockCtrl = TextEditingController(
      text: product == null ? '' : product.stock.toString(),
    );
    var imageUrl = product?.imageUrl;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Create product' : 'Edit product'),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockCtrl,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final file = await picker.pickImage(source: ImageSource.gallery);
                    if (file == null) {
                      return;
                    }
                    imageUrl = await _storageService.uploadProductImage(file);
                  },
                  child: const Text('Upload image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

                if (product == null) {
                  await productProvider.createProduct(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    category: categoryCtrl.text.trim(),
                    price: price,
                    stock: stock,
                    imageUrl: imageUrl,
                  );
                } else {
                  await productProvider.updateProduct(
                    id: product.id,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    category: categoryCtrl.text.trim(),
                    price: price,
                    stock: stock,
                    imageUrl: imageUrl,
                    isActive: product.isActive,
                  );
                }

                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCouponDialog() async {
    final adminProvider = context.read<AdminProvider>();
    final codeCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'percent');
    final valueCtrl = TextEditingController();
    final minCtrl = TextEditingController(text: '0');
    final maxCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create coupon'),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(labelText: 'Type (percent/fixed)'),
              ),
              TextField(
                controller: valueCtrl,
                decoration: const InputDecoration(labelText: 'Discount value'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: minCtrl,
                decoration: const InputDecoration(labelText: 'Min order amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: maxCtrl,
                decoration: const InputDecoration(labelText: 'Max discount (optional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await adminProvider.createCoupon(
                code: codeCtrl.text.trim(),
                discountType: typeCtrl.text.trim(),
                discountValue: double.tryParse(valueCtrl.text.trim()) ?? 0,
                minOrderAmount: double.tryParse(minCtrl.text.trim()) ?? 0,
                maxDiscount: maxCtrl.text.trim().isEmpty
                    ? null
                    : double.tryParse(maxCtrl.text.trim()),
                startAt: DateTime.now().subtract(const Duration(days: 1)),
                endAt: DateTime.now().add(const Duration(days: 30)),
              );

              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Coupons'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () => _openProductDialog(),
                    child: const Text('Add product'),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.category} | \$${product.price.toStringAsFixed(2)}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            onPressed: () => _openProductDialog(product: product),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () =>
                                productProvider.deleteProduct(product.id),
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: _openCouponDialog,
                    child: const Text('Create coupon'),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: adminProvider.coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = adminProvider.coupons[index];
                    return SwitchListTile(
                      value: coupon.isActive,
                      title: Text(coupon.code),
                      subtitle: Text(
                        '${coupon.discountType} ${coupon.discountValue}',
                      ),
                      onChanged: (value) =>
                          adminProvider.toggleCouponStatus(coupon.id, value),
                      secondary: IconButton(
                        onPressed: () => adminProvider.deleteCoupon(coupon.id),
                        icon: const Icon(Icons.delete),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          ListView.builder(
            itemCount: adminProvider.allOrders.length,
            itemBuilder: (context, index) {
              final order = adminProvider.allOrders[index];
              return ListTile(
                title: Text('Order #${order.id}'),
                subtitle: Text(
                  'Status: ${order.status} | Total: \$${order.totalAmount.toStringAsFixed(2)}',
                ),
                trailing: DropdownButton<String>(
                  value: order.status,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('pending')),
                    DropdownMenuItem(value: 'paid', child: Text('paid')),
                    DropdownMenuItem(value: 'shipped', child: Text('shipped')),
                    DropdownMenuItem(value: 'completed', child: Text('completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('cancelled')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    adminProvider.updateOrderStatus(order.id, value);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
