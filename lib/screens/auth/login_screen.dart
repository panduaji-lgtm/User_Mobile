import 'package:flutter/material.dart';
import '../main_navigation.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan email dan kata sandi Anda'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.login(email: email, password: password);
      if (!mounted) return;
      setState(() => _isLoading = false);

      AppLoadingOverlay.navigateWithLoading(
        context,
        targetScreen: const MainNavigation(),
        replace: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : 'pengunjung.google@gmail.com';
      await AuthService.loginWithGoogle(email: email);
      if (!mounted) return;
      setState(() => _isLoading = false);

      AppLoadingOverlay.navigateWithLoading(
        context,
        targetScreen: const MainNavigation(),
        replace: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailDialogController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Color(0xFF3F5243)),
                  SizedBox(width: 8),
                  Text(
                    'Lupa Kata Sandi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C322B),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan email yang terdaftar untuk menerima link reset kata sandi.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF727A71)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailDialogController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'nama@email.com',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA0A7A0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE0E3DF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: Color(0xFF727A71))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F5243),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final inputEmail = emailDialogController.text.trim();
                          if (inputEmail.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Silakan masukkan email'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            final res = await AuthService.forgotPassword(email: inputEmail);
                            final token = res['resetToken'] as String;
                            if (!mounted) return;
                            Navigator.pop(ctx); // Close dialog

                            // Show snackbar with action / direct link to reset password form
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Email terdaftar! Klik tombol untuk mereset kata sandi.'),
                                backgroundColor: const Color(0xFF3F5243),
                                duration: const Duration(seconds: 10),
                                action: SnackBarAction(
                                  label: 'BUAT PASSWORD BARU',
                                  textColor: const Color(0xFFCBB26A),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ResetPasswordScreen(
                                          token: token,
                                          email: inputEmail,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );

                            // Also automatically navigate to ResetPasswordScreen for best UX
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResetPasswordScreen(
                                  token: token,
                                  email: inputEmail,
                                ),
                              ),
                            );
                          } catch (err) {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err.toString().replaceAll('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Kirim Link Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Sesuai Desain UI
    const Color bgCream = Color(0xFFF7F3EA);
    const Color cardBg = Colors.white;
    const Color darkGreen = Color(0xFF3F5243);
    const Color goldAccent = Color(0xFFCBB26A);
    const Color textDark = Color(0xFF2C322B);
    const Color textMuted = Color(0xFF727A71);
    const Color borderLight = Color(0xFFE0E3DF);

    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Header (Logo + Title + Register Button)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: darkGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: goldAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'MUSEUM BRAWIJAYA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Card Formulir Login
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Judul & Subtitle
                      const Text(
                        'Masuk Ke Akun Anda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Masuk untuk memesan tiket dan menyimpan koleksi favorit',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Input Email
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Masukkan email Anda',
                          hintStyle: const TextStyle(color: Color(0xFFA0A7A0), fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderLight),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Input Kata Sandi
                      const Text(
                        'Kata Sandi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Masukkan kata sandi Anda',
                          hintStyle: const TextStyle(color: Color(0xFFA0A7A0), fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderLight),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Checkbox Ingat Saya & Lupa Kata Sandi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: darkGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ingat saya',
                                style: TextStyle(fontSize: 12, color: textDark),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showForgotPasswordDialog,
                            child: const Text(
                              'Lupa kata sandi?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tombol Masuk Utama
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Pembatas "ATAU"
                      Row(
                        children: const [
                          Expanded(child: Divider(color: borderLight)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'ATAU',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFA0A7A0),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: borderLight)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tombol "Lanjut dengan Google"
                      OutlinedButton(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(color: borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.g_mobiledata_rounded, size: 24, color: textDark),
                            SizedBox(width: 6),
                            Text(
                              'Lanjut dengan Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer "Belum punya akun? Daftar disini"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Daftar disini',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}