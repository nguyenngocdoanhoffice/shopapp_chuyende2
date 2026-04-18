import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/user_management_provider.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';

class UserManagementScreen extends StatefulWidget {
  final bool embedded;

  const UserManagementScreen({super.key, this.embedded = false});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementProvider>().loadUsers();
    });
  }

  Future<void> _openUserDetail(AppUser user) async {
    final provider = context.read<UserManagementProvider>();
    final detail = await provider.getUserDetail(user.id);
    if (!mounted || detail == null) {
      return;
    }

    var role = detail.role;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Chi tiet nguoi dung'),
            content: SizedBox(
              width: 420,
              child: ListView(
                shrinkWrap: true,
                children: [
                  _line('Ho ten', detail.fullName),
                  _line('Email', detail.email),
                  _line('So dien thoai', detail.phone),
                  _line('Dia chi', detail.address),
                  _line(
                    'Ngay tao',
                    detail.createdAt?.toLocal().toString() ?? '',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Vai tro'),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('user')),
                      DropdownMenuItem(value: 'admin', child: Text('admin')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        role = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dong'),
              ),
              FilledButton(
                onPressed: () async {
                  await provider.updateUserRole(userId: detail.id, role: role);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Cap nhat vai tro'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserManagementProvider>();

    final body = provider.isLoading
        ? const AppLoading(message: 'Dang tai nguoi dung')
        : provider.users.isEmpty
        ? const AppEmptyState(
            icon: Icons.people_alt_outlined,
            title: 'Khong co nguoi dung',
            subtitle: 'Danh sach nguoi dung se hien thi tai day.',
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.users.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = provider.users[index];
              return AppSectionCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _openUserDetail(user),
                  leading: CircleAvatar(
                    child: Text(
                      (user.fullName.isNotEmpty ? user.fullName : 'U')[0]
                          .toUpperCase(),
                    ),
                  ),
                  title: Text(
                    user.fullName.isEmpty ? user.email : user.fullName,
                  ),
                  subtitle: Text('${user.email}\nRole: ${user.role}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quan ly nguoi dung')),
      body: body,
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
