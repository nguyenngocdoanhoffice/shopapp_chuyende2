import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

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

    _nameCtrl.text = user?.fullName ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _addressCtrl.text = user?.address ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Email: ${user?.email ?? ''}'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
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
                    content: Text(ok ? 'Profile saved' : 'Profile save failed'),
                  ),
                );
              },
              child: const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}
