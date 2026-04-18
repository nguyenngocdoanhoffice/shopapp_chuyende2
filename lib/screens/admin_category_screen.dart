import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';

class AdminCategoryScreen extends StatefulWidget {
  final bool embedded;

  const AdminCategoryScreen({super.key, this.embedded = false});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  Future<void> _openCategoryDialog({Category? category}) async {
    final provider = context.read<CategoryProvider>();
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descriptionCtrl = TextEditingController(
      text: category?.description ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Tao danh muc' : 'Sua danh muc'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ten danh muc'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Mo ta'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                return;
              }
              if (category == null) {
                await provider.createCategory(
                  name: name,
                  description: descriptionCtrl.text.trim(),
                );
              } else {
                await provider.updateCategory(
                  id: category.id,
                  name: name,
                  description: descriptionCtrl.text.trim(),
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
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final provider = context.read<CategoryProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa danh muc'),
        content: Text('Ban co chac chan muon xoa "${category.name}"?'),
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

    if (ok == true) {
      await provider.deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    final content = Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: FilledButton.icon(
              onPressed: () => _openCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Them danh muc'),
            ),
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const AppLoading(message: 'Dang tai danh muc')
              : provider.categories.isEmpty
              ? const AppEmptyState(
                  icon: Icons.category_outlined,
                  title: 'Chua co danh muc',
                  subtitle: 'Hay tao danh muc dau tien.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.categories.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return AppSectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(category.description),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _openCategoryDialog(category: category),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => _deleteCategory(category),
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

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quan ly danh muc')),
      body: content,
    );
  }
}
