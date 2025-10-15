import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool isEmailConfirmed() {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    _isLoading = true;
    try {
      return await _supabase.auth.signInWithPassword(
        password: password,
        email: email,
      );
    } catch (e) {
      if (e is AuthException) {
        switch (e.message) {
          case 'Invalid login credentials':
            throw Exception('Kullanıcı adı veya şifre hatalı');
          case 'Email not confirmed':
            throw Exception('Email adresinizi doğrulayın');
          case 'Too many requests':
            throw Exception('Çok fazla deneme yaptınız, lütfen bekleyin');
          default:
            throw Exception('Giriş yapılamadı: ${e.message}');
        }
      } else if (e is SocketException) {
        // İnternet bağlantısı hatası
        throw Exception('İnternet bağlantınızı kontrol edin');
      } else {
        // Diğer hatalar
        throw Exception('Beklenmeyen bir hata oluştu');
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw Exception('Email doğrulama gönderilemedi');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception("Çıkış yapılırken hata oluştu");
    }
  }
}
