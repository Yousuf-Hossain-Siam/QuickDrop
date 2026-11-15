import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/features/bottom_nav/presentation/bottom_navigator.dart';
import 'login_screen.dart';
import 'package:flutter_pos_background_upload_download/features/auth/providers/splash_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final session = ref.watch(splashSessionProvider);

        ref.listen<AsyncValue<bool>>(splashSessionProvider, (_, next) {
          next.whenData((hasSession) {
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    hasSession ? const BottomNavigator() : const LoginScreen(),
              ),
            );
          });
        });

        return session.when(
          loading: () => const _SplashContent(),
          data: (_) => const _SplashContent(),
          error: (error, _) => _SplashError(
            onRetry: () => ref.invalidate(splashSessionProvider),
          ),
        );
      },
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/quickdrop.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            SizedBox(height: 18),
            Text(
              'QUICKDROP',
              style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),
            const Text('Could not restore your session.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
