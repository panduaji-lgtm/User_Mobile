import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/network/api_client.dart';
import 'package:app/models/auth_models.dart';
import 'package:app/viewmodels/auth_viewmodel.dart';
import 'package:app/views/widgets/app_loading_overlay.dart';

class RegisterScreen extends StatefulWidget {
  final AuthViewModel? viewModel;

  const RegisterScreen({super.key, this.viewModel});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final AuthViewModel _viewModel;
  late final bool _ownsViewModel;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isBusy => _viewModel.isBusy;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? AuthViewModel();
    _viewModel.preloadGoogleSignInConfig();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap minimal 3 karakter'), backgroundColor: Colors.red),
      );
      return;
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid'), backgroundColor: Colors.red),
      );
      return;
    }
    if (pass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi minimal 8 karakter'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!pass.contains(RegExp(r'[A-Z]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi harus memiliki huruf besar'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!pass.contains(RegExp(r'[a-z]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi harus memiliki huruf kecil'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!pass.contains(RegExp(r'[0-9]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi harus memiliki angka'), backgroundColor: Colors.red),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final user = await _viewModel.register(nama: name, email: email, password: pass);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pendaftaran berhasil! Akun dan password telah tersimpan ke database. Selamat datang, ${user.nama}'),
          backgroundColor: const Color(0xFF3F5243),
          duration: const Duration(seconds: 2),
        ),
      );

      // Berpindah ke menu utama dengan transisi loading overlay
      await AppLoadingOverlay.navigateWithLoading(
        context,
        targetRoute: '/',
        replace: true,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleGoogleRegister() async {
    if (_isBusy) return;
    try {
      final user = await _viewModel.loginWithGoogle();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil masuk dengan Google! Selamat datang, ${user.nama}'),
          backgroundColor: const Color(0xFF3F5243),
          duration: const Duration(seconds: 2),
        ),
      );

      if (mounted) {
        context.go('/');
      }
    } on GoogleAuthCancelledException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.blueGrey.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } on GoogleAuthConfigException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgCream = Color(0xFFF7F3EA);
    const Color cardBg = Colors.white;
    const Color darkGreen = Color(0xFF3F5243);
    const Color goldAccent = Color(0xFFCBB26A);
    const Color textDark = Color(0xFF2C322B);
    const Color textMuted = Color(0xFF727A71);
    const Color borderLight = Color(0xFFE0E3DF);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgCream,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
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
                          const Flexible(
                            child: Text(
                              'MUSEUM BRAWIJAYA',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textDark,
                        side: const BorderSide(color: borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      ),
                      child: const Text(
                        'Login',
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

              // Card Register
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
                      const Text(
                        'Buat Akun Baru',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Daftar akun untuk kemudahan pemesanan tiket museum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Input Nama Lengkap
                      const Text(
                        'Nama Lengkap',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama lengkap Anda',
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
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

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
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Buat kata sandi baru',
                          hintStyle: const TextStyle(color: Color(0xFFA0A7A0), fontSize: 13),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textMuted,
                              size: 19,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
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
                      const SizedBox(height: 6),
                      const Text(
                        'Minimal 8 karakter (kombinasi huruf besar, huruf kecil, dan angka)',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                      const SizedBox(height: 16),

                      // Input Konfirmasi Kata Sandi
                      const Text(
                        'Konfirmasi Kata Sandi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_isBusy) _handleRegister();
                        },
                        decoration: InputDecoration(
                          hintText: 'Ulangi kata sandi Anda',
                          hintStyle: const TextStyle(color: Color(0xFFA0A7A0), fontSize: 13),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textMuted,
                              size: 19,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
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
                      const SizedBox(height: 24),

                      // Tombol Daftar
                      ElevatedButton(
                        onPressed: _isBusy ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _viewModel.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Daftar Sekarang',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 18),

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
                      const SizedBox(height: 18),

                      // Tombol "Daftar dengan Google"
                      OutlinedButton(
                        onPressed: _isBusy ? null : _handleGoogleRegister,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(color: borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _viewModel.isGoogleLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: darkGreen,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Menghubungkan ke Google...',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: darkGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata_rounded, size: 24, color: textDark),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Daftar dengan Google',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Footer
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.go('/login');
                            },
                            child: const Text(
                              'Masuk disini',
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
      },
    );
  }
}