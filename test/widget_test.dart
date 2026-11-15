import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/app/app.dart';
import 'package:flutter_pos_background_upload_download/core/network/api_client.dart';
import 'package:flutter_pos_background_upload_download/features/auth/data/auth_repository.dart';
import 'package:flutter_pos_background_upload_download/features/auth/presentation/login_screen.dart';
import 'package:flutter_pos_background_upload_download/features/auth/providers/auth_providers.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(ApiClient());

  @override
  Future<void> login(String username, String password) async {}
}

void main() {
  testWidgets('shows the QuickDrop splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuickDrop()));
    expect(find.text('QUICKDROP'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('submits entered login credentials', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'quickdrop-user');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter both username and password.'), findsNothing);
  });
}
