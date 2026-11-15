import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_pos_background_upload_download/core/network/api_client.dart';
import 'package:flutter_pos_background_upload_download/features/auth/data/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final loginUsernameProvider = StateProvider.autoDispose<String>((ref) => '');
final loginPasswordProvider = StateProvider.autoDispose<String>((ref) => '');
final loginObscurePasswordProvider = StateProvider.autoDispose<bool>(
  (ref) => true,
);
final loginLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
final loginErrorProvider = StateProvider.autoDispose<String?>((ref) => null);
