import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthNotifier extends StateNotifier<User?> {
  late final StreamSubscription<AuthState> _authSubscription;
  final SupabaseClient _client = Supabase.instance.client;

  static const String _webClientId =
      '249414775385-4og8f2a4ctag3u1ukkps6rkuf43s5clt.apps.googleusercontent.com';
  static const String _iosClientId =
      '249414775385-ju36kgitjsjb1dt7r35tk9cnggromobc.apps.googleusercontent.com';

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

  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(email: email.trim(), password: password);
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://lift-9ecb1.web.app',
      );
      return;
    }

    final googleSignIn = GoogleSignIn(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _iosClientId
          : null,
      serverClientId: _webClientId,
      scopes: ['email', 'openid'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('ไม่พบ ID Token จากระบบ Google Sign-In');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('ไม่พบ Identity Token จากระบบ Apple Sign-In');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
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
