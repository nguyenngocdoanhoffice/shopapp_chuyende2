import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/auth_provider.dart';
import '../ui/widgets/app_state_widgets.dart';
import '../ui/widgets/app_surfaces.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userProfile;

    if (!_prefilled) {
      _nameCtrl.text = user?.fullName ?? '';
      _phoneCtrl.text = user?.phone ?? '';
      _addressCtrl.text = user?.address ?? '';
      _prefilled = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myProfile)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            AppSectionCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      (user?.fullName.isNotEmpty == true
                              ? user!.fullName
                              : 'U')[0]
                          .toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName
                              : AppStrings.myProfile,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(user?.email ?? ''),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (authProvider.error != null)
              AppErrorBanner(message: authProvider.error!),
            AppSectionCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.fullName,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.phone,
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: AppStrings.address,
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final ok = await authProvider.updateProfile(
                  fullName: _nameCtrl.text.trim(),
                  phone: _phoneCtrl.text.trim(),
                  address: _addressCtrl.text.trim(),
                );
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? AppStrings.profileSaved
                          : AppStrings.profileSaveFailed,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text(AppStrings.saveProfile),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Doi mat khau'),
            ),
          ],
        ),
      ),
    );
  }
}
