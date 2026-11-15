import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/core/network/api_client.dart';
import 'package:flutter_pos_background_upload_download/features/bottom_nav/presentation/bottom_navigator.dart';
import 'package:flutter_pos_background_upload_download/features/auth/providers/auth_providers.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final loading = ref.watch(loginLoadingProvider);
        final error = ref.watch(loginErrorProvider);
        final enteredUsername = ref.watch(loginUsernameProvider);
        final enteredPassword = ref.watch(loginPasswordProvider);

        Future<void> login() async {
          final username = enteredUsername.trim();
          final password = enteredPassword;
          if (username.isEmpty || password.isEmpty) {
            ref.read(loginErrorProvider.notifier).state =
                'Enter both username and password.';
            return;
          }
          ref.read(loginLoadingProvider.notifier).state = true;
          ref.read(loginErrorProvider.notifier).state = null;
          try {
            await ref.read(authRepositoryProvider).login(username, password);
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BottomNavigator()),
              );
            }
          } on DioException catch (error) {
            ref.read(loginErrorProvider.notifier).state =
                ApiClient.userMessageFor(error);
          } on FormatException catch (error) {
            ref.read(loginErrorProvider.notifier).state = error.message;
          } finally {
            ref.read(loginLoadingProvider.notifier).state = false;
          }
        }

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cloud_sync_rounded,
                        size: 56,
                        color: Color.fromARGB(255, 142, 219, 154),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome to QuickDrop',
                        style: TextStyle(
                          color: Color(0xFF52705A),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sign in to manage your POS file transfers.',
                        style: TextStyle(color: Color(0xFF52705A)),
                      ),
                      const SizedBox(height: 34),
                      TextField(
                        onChanged: (value) =>
                            ref.read(loginUsernameProvider.notifier).state =
                                value,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _PasswordField(),
                      if (error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          error,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B8B4D),
                            foregroundColor: Colors.white,
                          ),
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final obscurePassword = ref.watch(loginObscurePasswordProvider);

        return TextField(
          onChanged: (value) =>
              ref.read(loginPasswordProvider.notifier).state = value,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () {
                ref.read(loginObscurePasswordProvider.notifier).state =
                    !obscurePassword;
              },
              tooltip: obscurePassword ? 'Show password' : 'Hide password',
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        );
      },
    );
  }
}
