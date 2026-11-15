import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/features/auth/presentation/login_screen.dart';
import 'package:flutter_pos_background_upload_download/features/auth/providers/auth_providers.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const CircleAvatar(
            radius: 42,
            child: Icon(Icons.person_outline, size: 44),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'POS account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          Consumer(
            builder: (context, ref, child) => OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }
}
