import 'package:dent_bul_hospital_app/auth/auth_service.dart';
import 'package:dent_bul_hospital_app/clinic_profile_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isloading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xff21254A),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: height * .25,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_hospital,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Merhaba, \nHoşgeldin",
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    customSizeBox(),
                    TextField(
                      controller: _emailController,
                      decoration: customInputDecoration("Mail Adresi"),
                    ),
                    customSizeBox(),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Şifre",
                        hintStyle: TextStyle(color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    customSizeBox(),
                    Center(
                      child: TextButton(
                        onPressed: () => _showForgotPasswordDialog(),
                        child: Text(
                          "Şifremi Unuttum",
                          style: TextStyle(color: Colors.pink[200]),
                        ),
                      ),
                    ),
                    customSizeBox(),
                    Center(
                      child: TextButton(
                        onPressed: _isloading ? null : () async {
                          setState(() {
                            _isloading = true;
                          });
                          try {
                            final clinic = await _authService.signInWithClinicCredentials(
                              _emailController.text,
                              _passwordController.text,
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClinicProfilePage(
                                  clinicId: clinic!['id'],
                                ),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Giriş Başarılı!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst("Exception: ", ""),
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          } finally {
                            setState(() {
                              _isloading = false;
                            });
                          }
                        },
                        child: Container(
                          height: 50,
                          width: 150,
                          margin: EdgeInsets.symmetric(horizontal: 60),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: _isloading ? Colors.grey : Color(0xff31274F),
                          ),
                          child: Center(
                            child: _isloading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    "Giriş Yap",
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    customSizeBox(),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          "Hesap Oluştur",
                          style: TextStyle(color: Colors.pink[200]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Şifre Sıfırlama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email adresinizi girin, şifre sıfırlama linki gönderilecektir.'),
            SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'ornek@email.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Email adresi giriniz')),
                );
                return;
              }
              
              try {
                await _authService.resetPassword(emailController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Şifre sıfırlama emaili gönderildi')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: Text('Gönder'),
          ),
        ],
      ),
    );
  }

  Widget customSizeBox() => SizedBox(height: 20);
  InputDecoration customInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

