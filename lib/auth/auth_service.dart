import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>?> signInWithClinicCredentials(
    String email,
    String password,
  ) async {
    _isLoading = true;
    try {
      // Önce Supabase Auth ile giriş yap
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Auth başarılıysa, clinics tablosundan clinic bilgilerini getir
      final clinic = await _supabase
          .from('clinics')
          .select()
          .eq('email', email)
          .single();
      
      return clinic;
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
      } else if (e is PostgrestException) {
        throw Exception('Bu email adresi klinik sisteminde kayıtlı değil');
      } else {
        throw Exception('Beklenmeyen bir hata oluştu: $e');
      }
    } finally {
      _isLoading = false;
    }
  }


  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception("Çıkış yapılırken hata oluştu");
    }
  }


  // Şifre değiştirme metodu (Supabase Auth için)
  Future<void> changePassword(String email, String currentPassword, String newPassword) async {
    try {
      // Önce mevcut şifre ile doğrulama
      await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      
      // Yeni şifre ile güncelle
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Şifre değiştirilemedi: $e');
    }
  }

  // Email ile şifre sıfırlama (Supabase Auth için)
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Şifre sıfırlama emaili gönderilemedi: $e');
    }
  }
}
