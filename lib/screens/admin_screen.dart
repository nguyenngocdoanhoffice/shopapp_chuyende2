import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../providers/admin_provider.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../providers/user_management_provider.dart';
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
    _tabController = TabController(length: 6, vsync: this);

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
              title: Text(product == null ? 'Tạo sản phẩm' : 'Sửa sản phẩm'),
              content: SizedBox(
                width: 440,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Tên'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
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
                          labelText: 'Danh mục',
                        ),
                      )
                    else
                      const Text(
                        'Chưa có danh mục. Vui lòng tạo danh mục trước.',
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Giá'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stockCtrl,
                      decoration: const InputDecoration(labelText: 'Tồn kho'),
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
                                child: Text('Không thể tải ảnh'),
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
                              content: Text('Tải ảnh thành công'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tải ảnh thất bại: $e'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Tải ảnh lên'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
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
                  child: const Text('Lưu'),
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
    final valueCtrl = TextEditingController();

    DateTime startAt = DateTime.now().subtract(const Duration(days: 1));
    DateTime endAt = DateTime.now().add(const Duration(days: 30));
    // capture context before awaiting to avoid use_build_context_synchronously lint
    final callerContext = context;
    final userProvider = callerContext.read<UserManagementProvider>();
    await userProvider.loadUsers();
    if (!mounted) return;
    final users = List.of(userProvider.users);
    final selectedUserIds = <String>{};

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Tạo mã giảm giá'),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Mã'),
                ),
                TextField(
                  controller: valueCtrl,
                  decoration: const InputDecoration(labelText: 'Giảm (%)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bắt đầu: ${startAt.day}/${startAt.month}/${startAt.year}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: startAt,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => startAt = picked);
                        }
                      },
                      child: const Text('Chọn'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kết thúc: ${endAt.day}/${endAt.month}/${endAt.year}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: endAt,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => endAt = picked);
                        }
                      },
                      child: const Text('Chọn'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Text(
                  'Chọn người dùng áp dụng mã (bỏ trống = tất cả)',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (userProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (users.isEmpty)
                  const Text('Không có người dùng')
                else
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (ctx, i) {
                        final u = users[i];
                        final checked = selectedUserIds.contains(u.id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selectedUserIds.add(u.id);
                              } else {
                                selectedUserIds.remove(u.id);
                              }
                            });
                          },
                          title: Text(
                            u.fullName.isNotEmpty ? u.fullName : u.email,
                          ),
                          subtitle: Text(u.email),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final selected = selectedUserIds.isEmpty
                    ? null
                    : selectedUserIds.toList();
                await adminProvider.createCoupon(
                  code: codeCtrl.text.trim(),
                  discountType: 'percent',
                  discountValue: double.tryParse(valueCtrl.text.trim()) ?? 0,
                  minOrderAmount: 0,
                  maxDiscount: null,
                  startAt: startAt,
                  endAt: endAt,
                  applicableUserIds: selected,
                );

                if (!context.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final productProvider = context.read<ProductProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
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
            Tab(text: 'Báo cáo'),
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
          _ReportsTab(
            orders: adminProvider.allOrders,
            products: productProvider.products,
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

  static const int _lowStockThreshold = 5;

  const _ProductsTab({
    required this.products,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStockProducts = products
        .where((product) => product.stock <= 0)
        .toList();
    final lowStockProducts = products
        .where(
          (product) => product.stock > 0 && product.stock <= _lowStockThreshold,
        )
        .toList();

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
        if (outOfStockProducts.isNotEmpty || lowStockProducts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.error),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cảnh báo tồn kho',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (outOfStockProducts.isNotEmpty)
                    Text(
                      'Hết hàng: ${outOfStockProducts.map((e) => e.name).join(', ')}. Hãy mở từng sản phẩm để nhập thêm số lượng.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  if (lowStockProducts.isNotEmpty) ...[
                    if (outOfStockProducts.isNotEmpty)
                      const SizedBox(height: 6),
                    Text(
                      'Sắp hết hàng: ${lowStockProducts.map((e) => '${e.name} (${e.stock})').join(', ')}.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Bạn có thể sửa ngay trong Admin > Sản phẩm bằng nút chỉnh sửa để tăng tồn kho.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    if (product.stock <= 0)
                                      _StockBadge(
                                        label: 'Hết hàng',
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      )
                                    else if (product.stock <=
                                        _lowStockThreshold)
                                      _StockBadge(
                                        label: 'Sắp hết (${product.stock})',
                                        color: Colors.orange,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(product.category),
                                const SizedBox(height: 2),
                                PriceText(product.price),
                                const SizedBox(height: 2),
                                Text(
                                  'Tồn kho: ${product.stock}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
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

class _StockBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StockBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
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
                                const SizedBox(height: 4),
                                if (coupon.startAt != null &&
                                    coupon.endAt != null)
                                  Text(
                                    'Hạn: ${coupon.startAt!.day}/${coupon.startAt!.month}/${coupon.startAt!.year} - ${coupon.endAt!.day}/${coupon.endAt!.month}/${coupon.endAt!.year}',
                                  ),
                                if (coupon.applicableUserIds != null &&
                                    coupon.applicableUserIds!.isNotEmpty)
                                  Text(
                                    'Áp dụng cho: ${coupon.applicableUserIds!.length} user',
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
                        builder: (_) => OrderDetailScreen(
                          orderId: order.id,
                          sequence: index + 1,
                        ),
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
                            Text('Tổng: ${order.totalAmount.round()} ₫'),
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

enum _ReportPeriod { day, month, year }

class _ReportsTab extends StatefulWidget {
  final List<Order> orders;
  final List<Product> products;

  const _ReportsTab({required this.orders, required this.products});

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  _ReportPeriod _period = _ReportPeriod.month;
  DateTime _anchorDate = DateTime.now();

  static const List<String> _monthNames = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  List<Order> _filteredOrders() {
    final completed = widget.orders
        .where((order) => order.status == 'completed')
        .toList();

    bool matches(Order order) {
      final date = order.createdAt.toLocal();
      switch (_period) {
        case _ReportPeriod.day:
          return date.year == _anchorDate.year &&
              date.month == _anchorDate.month &&
              date.day == _anchorDate.day;
        case _ReportPeriod.month:
          return date.year == _anchorDate.year &&
              date.month == _anchorDate.month;
        case _ReportPeriod.year:
          return date.year == _anchorDate.year;
      }
    }

    return completed.where(matches).toList();
  }

  Map<int, int> _soldQtyMap(List<Order> filteredOrders) {
    final sold = <int, int>{};
    for (final order in filteredOrders) {
      for (final item in order.items) {
        sold[item.productId] = (sold[item.productId] ?? 0) + item.quantity;
      }
    }
    return sold;
  }

  double _revenue(List<Order> filteredOrders) {
    return filteredOrders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
  }

  String _periodLabel() {
    switch (_period) {
      case _ReportPeriod.day:
        return 'ngày ${_anchorDate.day}/${_anchorDate.month}/${_anchorDate.year}';
      case _ReportPeriod.month:
        return 'tháng ${_anchorDate.month}/${_anchorDate.year}';
      case _ReportPeriod.year:
        return 'năm ${_anchorDate.year}';
    }
  }

  Future<void> _setPeriodAndPick(_ReportPeriod period) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _period = period;
    });

    await _pickDate();
  }

  Future<void> _pickDate() async {
    switch (_period) {
      case _ReportPeriod.day:
        await _pickDay();
        return;
      case _ReportPeriod.month:
        await _pickMonth();
        return;
      case _ReportPeriod.year:
        await _pickYear();
        return;
    }
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _anchorDate = picked;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        var selectedYear = _anchorDate.year;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chọn tháng'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: selectedYear <= 2020
                              ? null
                              : () {
                                  setState(() {
                                    selectedYear--;
                                  });
                                },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          selectedYear.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: selectedYear >= 2100
                              ? null
                              : () {
                                  setState(() {
                                    selectedYear++;
                                  });
                                },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.2,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        return OutlinedButton(
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                            ).pop(DateTime(selectedYear, month, 1));
                          },
                          child: Text(_monthNames[index]),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _anchorDate = picked;
    });
  }

  Future<void> _pickYear() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chọn năm'),
          content: SizedBox(
            width: 320,
            height: 360,
            child: YearPicker(
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              selectedDate: _anchorDate,
              onChanged: (value) {
                Navigator.of(dialogContext).pop(value.year);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _anchorDate = DateTime(picked, _anchorDate.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders();
    final soldMap = _soldQtyMap(filteredOrders);
    final revenue = _revenue(filteredOrders);

    final rankedProducts =
        widget.products
            .map(
              (product) => _ProductSalesRow(
                product: product,
                soldQuantity: soldMap[product.id] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));

    final bestSelling = rankedProducts
        .where((e) => e.soldQuantity > 0)
        .toList();
    final slowSelling = List.of(rankedProducts)
      ..sort((a, b) => a.soldQuantity.compareTo(b.soldQuantity));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lọc theo thời gian',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Ngày'),
                    selected: _period == _ReportPeriod.day,
                    onSelected: (_) => _setPeriodAndPick(_ReportPeriod.day),
                  ),
                  ChoiceChip(
                    label: const Text('Tháng'),
                    selected: _period == _ReportPeriod.month,
                    onSelected: (_) => _setPeriodAndPick(_ReportPeriod.month),
                  ),
                  ChoiceChip(
                    label: const Text('Năm'),
                    selected: _period == _ReportPeriod.year,
                    onSelected: (_) => _setPeriodAndPick(_ReportPeriod.year),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(switch (_period) {
                      _ReportPeriod.day => 'Chọn ngày',
                      _ReportPeriod.month => 'Chọn tháng',
                      _ReportPeriod.year => 'Chọn năm',
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Đang xem theo ${_periodLabel()}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doanh thu', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '${revenue.round()} ₫',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Chỉ tính các đơn hàng ở trạng thái Hoàn thành trong $_periodLabel().',
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
                'Sản phẩm bán chạy',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (bestSelling.isEmpty)
                const Text(
                  'Chưa có dữ liệu bán hàng trong khoảng thời gian này.',
                )
              else
                ...bestSelling
                    .take(5)
                    .map(
                      (row) => _ReportRow(
                        name: row.product.name,
                        value: '${row.soldQuantity} sản phẩm',
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
                'Sản phẩm bán chậm / chưa bán',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (slowSelling.isEmpty)
                const Text(
                  'Không có sản phẩm bán chậm trong khoảng thời gian này.',
                )
              else
                ...slowSelling
                    .take(5)
                    .map(
                      (row) => _ReportRow(
                        name: row.product.name,
                        value: '${row.soldQuantity} sản phẩm',
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductSalesRow {
  final Product product;
  final int soldQuantity;

  const _ProductSalesRow({required this.product, required this.soldQuantity});
}

class _ReportRow extends StatelessWidget {
  final String name;
  final String value;

  const _ReportRow({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text(value),
        ],
      ),
    );
  }
}
