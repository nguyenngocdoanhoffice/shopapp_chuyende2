import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/cart_provider.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, String> _qtyErrors = {};

  String _stockWarningText(String productName, int stock) {
    if (stock <= 0) {
      return '$productName hiện đã hết hàng. Vui lòng nhập thêm trong Admin > Products.';
    }

    return '$productName chỉ còn $stock sản phẩm trong kho. Nếu không đủ, vui lòng nhập thêm trong Admin > Products.';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  void dispose() {
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setQtyError(int itemId, String message) {
    setState(() {
      _qtyErrors[itemId] = message;
    });
  }

  void _clearQtyError(int itemId) {
    if (!_qtyErrors.containsKey(itemId)) {
      return;
    }
    setState(() {
      _qtyErrors.remove(itemId);
    });
  }

  String? _qtyErrorFor(int itemId) => _qtyErrors[itemId];

  int? _parseQuantity(String value) => int.tryParse(value.trim());

  void _syncControllerValue(int itemId, int quantity) {
    final controller = _qtyControllers[itemId];
    if (controller == null) {
      return;
    }

    final text = quantity.toString();
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  Future<bool> _commitPendingQuantities(CartProvider cartProvider) async {
    final itemsSnapshot = List.of(cartProvider.items);

    for (final item in itemsSnapshot) {
      final controller = _controllerFor(item.id, item.quantity);
      final stock = item.product?.stock ?? 0;
      final qty = _parseQuantity(controller.text);

      if (qty == null || qty <= 0) {
        _setQtyError(item.id, 'Vui lòng nhập số lượng hợp lệ.');
        return false;
      }

      if (qty > stock) {
        _setQtyError(
          item.id,
          _stockWarningText(item.product?.name ?? 'Sản phẩm', stock),
        );
        return false;
      }

      _clearQtyError(item.id);

      if (qty != item.quantity) {
        final ok = await cartProvider.updateItemQty(item.id, qty);
        if (!ok) {
          _setQtyError(
            item.id,
            cartProvider.error ?? 'Không thể cập nhật số lượng',
          );
          return false;
        }
        controller.text = qty.toString();
        _syncControllerValue(item.id, qty);
      }
    }

    return true;
  }

  TextEditingController _controllerFor(int cartItemId, int quantity) {
    return _qtyControllers.putIfAbsent(
      cartItemId,
      () => TextEditingController(text: quantity.toString()),
    );
  }

  void _syncControllers(List items) {
    final activeIds = items.map((item) => item.id).toSet();
    final removedIds = _qtyControllers.keys
        .where((id) => !activeIds.contains(id))
        .toList();
    for (final id in removedIds) {
      _qtyControllers.remove(id)?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    _syncControllers(cartProvider.items);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.yourCart)),
      body: cartProvider.isLoading
          ? const AppLoading(message: AppStrings.loadingCart)
          : cartProvider.items.isEmpty
          ? const AppEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: AppStrings.cartEmpty,
              subtitle: AppStrings.cartEmptySubtitle,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      final productName =
                          item.product?.name ?? 'S\u1ea3n ph\u1ea9m';
                      final stock = item.product?.stock ?? 0;
                      final qtyController = _controllerFor(
                        item.id,
                        item.quantity,
                      );
                      final qtyError = _qtyErrorFor(item.id);

                      return AppSectionCard(
                        child: Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.devices_other_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  // unit price removed as requested
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tồn kho: $stock',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _QtyButton(
                                        icon: Icons.remove,
                                        onTap: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final ok = await cartProvider
                                              .updateItemQty(
                                                item.id,
                                                item.quantity - 1,
                                              );
                                          if (!ok) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  cartProvider.error ??
                                                      'Không thể cập nhật số lượng',
                                                ),
                                              ),
                                            );
                                          } else {
                                            _clearQtyError(item.id);
                                            _syncControllerValue(
                                              item.id,
                                              item.quantity - 1,
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 64,
                                        child: TextField(
                                          controller: qtyController,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                  horizontal: 8,
                                                ),
                                            errorText: qtyError,
                                          ),
                                          onChanged: (value) {
                                            final qty = _parseQuantity(value);

                                            if (qty == null || qty <= 0) {
                                              _setQtyError(
                                                item.id,
                                                'Vui lòng nhập số lượng hợp lệ.',
                                              );
                                              return;
                                            }

                                            if (qty > stock) {
                                              _setQtyError(
                                                item.id,
                                                _stockWarningText(
                                                  productName,
                                                  stock,
                                                ),
                                              );
                                              return;
                                            }

                                            _clearQtyError(item.id);
                                          },
                                          onSubmitted: (value) async {
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final qty = _parseQuantity(value);
                                            if (qty == null || qty <= 0) {
                                              _setQtyError(
                                                item.id,
                                                'Vui lòng nhập số lượng hợp lệ.',
                                              );
                                              return;
                                            }
                                            if (qty > stock) {
                                              _setQtyError(
                                                item.id,
                                                _stockWarningText(
                                                  productName,
                                                  stock,
                                                ),
                                              );
                                              return;
                                            }
                                            _clearQtyError(item.id);
                                            final ok = await cartProvider
                                                .updateItemQty(item.id, qty);
                                            if (!ok) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    cartProvider.error ??
                                                        'Không thể cập nhật số lượng',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      _QtyButton(
                                        icon: Icons.add,
                                        onTap: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final nextQty = item.quantity + 1;
                                          if (nextQty > stock) {
                                            final warning = _stockWarningText(
                                              productName,
                                              stock,
                                            );
                                            _setQtyError(item.id, warning);
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(warning),
                                                duration: const Duration(
                                                  seconds: 4,
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          _clearQtyError(item.id);
                                          final ok = await cartProvider
                                              .updateItemQty(item.id, nextQty);
                                          if (!ok) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  cartProvider.error ??
                                                      'Không thể cập nhật số lượng',
                                                ),
                                              ),
                                            );
                                          } else {
                                            _syncControllerValue(
                                              item.id,
                                              nextQty,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  if (qtyError != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      ),
                                      child: Text(
                                        qtyError,
                                        softWrap: true,
                                        maxLines: 4,
                                        overflow: TextOverflow.visible,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onErrorContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                PriceText(item.lineTotal),
                                IconButton(
                                  onPressed: () =>
                                      cartProvider.removeItem(item.id),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(AppStrings.subtotal),
                            PriceText(cartProvider.subtotal),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            final canProceed = await _commitPendingQuantities(
                              cartProvider,
                            );
                            if (!canProceed) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Vui lòng sửa số lượng vượt tồn kho trước khi thanh toán.',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (!mounted) {
                              return;
                            }

                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.payment_outlined),
                          label: const Text(AppStrings.continueCheckout),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17),
      ),
    );
  }
}
