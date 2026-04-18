import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../providers/admin_provider.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../screens/admin_category_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/user_management_screen.dart';
import '../services/storage_service.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';

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
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = context.read<ProductProvider>();
      final adminProvider = context.read<AdminProvider>();
      final categoryProvider = context.read<CategoryProvider>();

      await productProvider.loadInitialData();
      await adminProvider.loadDashboardData();
      await categoryProvider.loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openProductDialog({Product? product}) async {
    final productProvider = context.read<ProductProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    if (categoryProvider.categories.isEmpty) {
      await categoryProvider.loadCategories();
      if (!mounted) {
        return;
      }
    }

    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final priceCtrl = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    final stockCtrl = TextEditingController(
      text: product == null ? '' : product.stock.toString(),
    );
    var imageUrl = product?.imageUrl;

    final categories = categoryProvider.categories;
    Category? selectedCategory;
    if (categories.isNotEmpty) {
      if (product?.categoryId != null) {
        for (final c in categories) {
          if (c.id == product!.categoryId) {
            selectedCategory = c;
            break;
          }
        }
      }
      selectedCategory ??= categories.first;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(product == null ? 'Tao san pham' : 'Sua san pham'),
              content: SizedBox(
                width: 440,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Ten'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Mo ta'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    if (categories.isNotEmpty)
                      DropdownButtonFormField<Category>(
                        initialValue: selectedCategory,
                        items: categories
                            .map(
                              (category) => DropdownMenuItem<Category>(
                                value: category,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Danh muc',
                        ),
                      )
                    else
                      const Text(
                        'Chua co danh muc. Vui long tao danh muc truoc.',
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Gia'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockCtrl,
                      decoration: const InputDecoration(labelText: 'Ton kho'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    if (imageUrl != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Khong the tai anh'),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (file == null) {
                          return;
                        }
                        try {
                          final uploadedUrl = await _storageService
                              .uploadProductImage(file);
                          setState(() {
                            imageUrl = uploadedUrl;
                          });
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tai anh thanh cong'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tai anh that bai: $e'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Tai anh len'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Huy'),
                ),
                ElevatedButton(
                  onPressed: selectedCategory == null
                      ? null
                      : () async {
                          final price =
                              double.tryParse(priceCtrl.text.trim()) ?? 0;
                          final stock =
                              int.tryParse(stockCtrl.text.trim()) ?? 0;

                          if (product == null) {
                            await productProvider.createProduct(
                              name: nameCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              category: selectedCategory!.name,
                              categoryId: selectedCategory!.id,
                              price: price,
                              stock: stock,
                              imageUrl: imageUrl,
                            );
                          } else {
                            await productProvider.updateProduct(
                              id: product.id,
                              name: nameCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              category: selectedCategory!.name,
                              categoryId: selectedCategory!.id,
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
                  child: const Text('Luu'),
                ),
              ],
            );
          },
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
        title: const Text('Tao ma giam gia'),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Ma'),
              ),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Loai (percent/fixed)',
                ),
              ),
              TextField(
                controller: valueCtrl,
                decoration: const InputDecoration(labelText: 'Gia tri giam'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: minCtrl,
                decoration: const InputDecoration(labelText: 'Don toi thieu'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: maxCtrl,
                decoration: const InputDecoration(labelText: 'Giam toi da'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huy'),
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
            child: const Text('Tao'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final productProvider = context.read<ProductProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xac nhan xoa'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huy'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await productProvider.deleteProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển quản trị'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Sản phẩm'),
            Tab(text: 'Danh mục'),
            Tab(text: 'Mã giảm giá'),
            Tab(text: 'Đơn hàng'),
            Tab(text: 'Người dùng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProductsTab(
            products: productProvider.products,
            onCreate: () => _openProductDialog(),
            onEdit: (product) => _openProductDialog(product: product),
            onDelete: _confirmDeleteProduct,
          ),
          const AdminCategoryScreen(embedded: true),
          _CouponsTab(
            isLoading: adminProvider.isLoading,
            coupons: adminProvider.coupons,
            onCreate: _openCouponDialog,
            onToggle: (id, value) =>
                adminProvider.toggleCouponStatus(id, value),
            onDelete: (id) => adminProvider.deleteCoupon(id),
          ),
          _OrdersTab(
            isLoading: adminProvider.isLoading,
            orders: adminProvider.allOrders,
            onStatus: (id, value) => adminProvider.updateOrderStatus(id, value),
          ),
          const UserManagementScreen(embedded: true),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final List<Product> products;
  final VoidCallback onCreate;
  final void Function(Product) onEdit;
  final void Function(Product) onDelete;

  const _ProductsTab({
    required this.products,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
            ),
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? const AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Không có sản phẩm',
                  subtitle: 'Tạo sản phẩm đầu tiên cho danh mục.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return AppSectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(product.category),
                                const SizedBox(height: 2),
                                PriceText(product.price),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => onEdit(product),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => onDelete(product),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CouponsTab extends StatelessWidget {
  final bool isLoading;
  final dynamic coupons;
  final VoidCallback onCreate;
  final void Function(int, bool) onToggle;
  final void Function(int) onDelete;

  const _CouponsTab({
    required this.isLoading,
    required this.coupons,
    required this.onCreate,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.discount_outlined),
              label: const Text('Tạo mã giảm giá'),
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const AppLoading(message: 'Đang tải mã giảm giá')
              : coupons.isEmpty
              ? const AppEmptyState(
                  icon: Icons.local_offer_outlined,
                  title: 'Không có mã giảm giá',
                  subtitle: 'Tạo mã giảm giá để tăng tỷ lệ chuyển đổi.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: coupons.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return AppSectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coupon.code,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${coupon.discountType} ${coupon.discountValue}',
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: coupon.isActive,
                            onChanged: (value) => onToggle(coupon.id, value),
                          ),
                          IconButton(
                            onPressed: () => onDelete(coupon.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final bool isLoading;
  final dynamic orders;
  final void Function(int, String) onStatus;

  const _OrdersTab({
    required this.isLoading,
    required this.orders,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const AppLoading(message: 'Đang tải đơn hàng')
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              return AppSectionCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đơn hàng #${order.id}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tổng: \$${order.totalAmount.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<String>(
                        value: order.status,
                        items: const [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Chờ xử lý'),
                          ),
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text('Đã thanh toán'),
                          ),
                          DropdownMenuItem(
                            value: 'shipped',
                            child: Text('Đã gửi'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Hoàn thành'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Đã hủy'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          onStatus(order.id, value);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
