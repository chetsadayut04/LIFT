import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends StateNotifier<User?> {
  late final StreamSubscription<AuthState> _authSubscription;
  final SupabaseClient _client = Supabase.instance.client;

  AuthNotifier() : super(Supabase.instance.client.auth.currentUser) {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      state = data.session?.user;
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: (displayName != null && displayName.trim().isNotEmpty)
          ? {'full_name': displayName.trim(), 'name': displayName.trim()}
          : null,
    );
  }

  Future<void> updateDisplayName(String name) async {
    final response = await _client.auth.updateUser(
      UserAttributes(data: {'full_name': name.trim(), 'name': name.trim()}),
    );
    if (response.user != null) {
      state = response.user;
    }
  }

  Future<void> updateAvatarUrl(String url) async {
    final response = await _client.auth.updateUser(
      UserAttributes(data: {'avatar_url': url}),
    );
    if (response.user != null) {
      state = response.user;
    }
  }

  Future<String> uploadAvatar(Uint8List bytes, String extension) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final cleanExt = extension.replaceAll('.', '').toLowerCase();
    final fileName =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$cleanExt';

    await _client.storage
        .from('avatars')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$cleanExt',
            upsert: true,
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);
    await updateAvatarUrl(publicUrl);
    return publicUrl;
  }

  Future<void> removeAvatar() async {
    final response = await _client.auth.updateUser(
      UserAttributes(data: {'avatar_url': null}),
    );
    if (response.user != null) {
      state = response.user;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: kIsWeb ? 'https://lift-9ecb1.web.app' : null,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class PasswordRecoveryNotifier extends StateNotifier<bool> {
  late final StreamSubscription<AuthState> _sub;

  PasswordRecoveryNotifier() : super(_checkInitialRecovery()) {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        state = true;
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = false;
      }
    });
  }

  static bool _checkInitialRecovery() {
    if (kIsWeb) {
      final uri = Uri.base;
      return uri.fragment.contains('type=recovery') ||
          uri.queryParameters['type'] == 'recovery' ||
          uri.toString().contains('type=recovery');
    }
    return false;
  }

  void completeRecovery() {
    state = false;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final passwordRecoveryProvider =
    StateNotifierProvider<PasswordRecoveryNotifier, bool>((ref) {
      return PasswordRecoveryNotifier();
    });
