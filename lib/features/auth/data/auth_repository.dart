import 'package:flutter_pos_background_upload_download/core/network/api_client.dart';

class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Future<void> login(String username, String password) async {
    await _client.login(username, password);
  }

  Future<bool> restoreSession() async {
    return (await _client.restoreToken()) != null;
  }

  Future<void> logout() => _client.clearToken();
}
