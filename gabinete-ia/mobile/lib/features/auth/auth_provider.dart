import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/preview_data.dart';

class AuthState {
  final bool isAuthenticated;
  final String? nome;
  final String? perfil;
  final String? gabineteId;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.nome,
    this.perfil,
    this.gabineteId,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? nome,
    String? perfil,
    String? gabineteId,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      nome: nome ?? this.nome,
      perfil: perfil ?? this.perfil,
      gabineteId: gabineteId ?? this.gabineteId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    if (!AppConstants.previewMode) {
      _checkSession();
    }
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _checkSession() async {
    final token = await _storage.read(key: 'access_token');
    final nome = await _storage.read(key: 'user_nome');
    final perfil = await _storage.read(key: 'user_perfil');
    final gabineteId = await _storage.read(key: 'gabinete_id');

    if (token != null) {
      state = AuthState(
        isAuthenticated: true,
        nome: nome,
        perfil: perfil,
        gabineteId: gabineteId,
      );
    }
  }

  Future<bool> login(String email, String senha) async {
    if (AppConstants.previewMode) {
      state = const AuthState(
        isAuthenticated: true,
        nome: PreviewData.userName,
        perfil: PreviewData.userRole,
        gabineteId: PreviewData.gabineteId,
      );
      return true;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await ApiClient.instance.post(
        '/auth/login',
        data: {'email': email, 'senha': senha},
      );
      final data = res.data as Map<String, dynamic>;
      await ApiClient.saveTokens(data['access_token'] as String, data['refresh_token'] as String);
      await _storage.write(key: 'user_nome', value: data['nome'] as String?);
      await _storage.write(key: 'user_perfil', value: data['perfil'] as String?);
      await _storage.write(key: 'gabinete_id', value: data['gabinete_id'] as String?);

      state = AuthState(
        isAuthenticated: true,
        nome: data['nome'] as String?,
        perfil: data['perfil'] as String?,
        gabineteId: data['gabinete_id'] as String?,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Credenciais inválidas. Verifique e tente novamente.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    if (AppConstants.previewMode) {
      state = const AuthState();
      return;
    }

    await ApiClient.clearTokens();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
