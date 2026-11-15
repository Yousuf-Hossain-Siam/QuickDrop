import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

final splashSessionProvider = FutureProvider<bool>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 900));
  return ref.read(authRepositoryProvider).restoreSession();
});
