<<<<<<<< HEAD:lib/features/auth/presentation/views/forgot_password_screen.dart
﻿import 'package:flutter/material.dart';

import 'package:app/features/auth/data/repositories/auth_service.dart';
========
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/viewmodels/auth_viewmodel.dart';
>>>>>>>> 0a1ba4f3b1715a24578dc0df51e399fd51460d94:lib/views/screens/auth/forgot_password_screen.dart

class ForgotPasswordScreen extends StatefulWidget {
  final AuthViewModel? viewModel;

  const ForgotPasswordScreen({super.key, this.viewModel});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  late final AuthViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? AuthViewModel();
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan alamat email Anda'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final res = await _viewModel.forgotPassword(email: email);
      if (!mounted) return;

      final data = res['data'] as Map<String, dynamic>? ?? {};
      final resetToken = data['resetToken'] as String? ?? '';
      final previewUrl = data['previewUrl'] as String?;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read, color: Color(0xFF3F5243)),
              SizedBox(width: 8),
              Expanded(
                child: Text('Email Reset Terkirim!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kode OTP 6 digit dan link reset kata sandi telah dikirim ke email "$email".',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Silakan periksa Kotak Masuk (Inbox) atau folder Spam pada email Anda untuk melihat kode OTP atau membuka tautan pengaturan ulang kata sandi.',
                style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
              ),
              if (previewUrl != null && previewUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Text(
                    'Email SMTP Ethereal telah aktif terkirim secara live ke server email.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/login');
              },
              child: const Text('Ke Halaman Login'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F5243),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final encodedEmail = Uri.encodeComponent(email);
                final encodedToken = Uri.encodeComponent(resetToken);
                context.go('/reset-password?email=$encodedEmail&token=$encodedToken');
              },
              child: const Text('Atur Kata Sandi Baru'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgCream = Color(0xFFF7F3EA);
    const darkGreen = Color(0xFF3F5243);
    const goldAccent = Color(0xFFCBB26A);
    const textDark = Color(0xFF2C322B);
    const textMuted = Color(0xFF727A71);
    const borderLight = Color(0xFFE0E3DF);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgCream,
          body: SafeArea(
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: darkGreen),
                    onPressed: () => context.go('/login'),
                  ),
                  const SizedBox(width: 4),
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
                  const Expanded(
                    child: Text(
                      'MUSEUM BRAWIJAYA',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5DFD2)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: bgCream,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.lock,
                                      color: darkGreen,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Lupa Kata Sandi?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF211F1D),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Masukkan alamat email akun Anda. Kami akan mengirimkan tautan reset kata sandi secara real-time ke email Anda.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 14,
                                    height: 1.5,
                                    color: textMuted,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Text(
                                  'Alamat Email',
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleForgotPassword(),
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan email Anda',
                                    hintStyle: const TextStyle(
                                      fontFamily: 'Lato',
                                      color: Color(0xFFA0A7A0),
                                      fontSize: 14,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFFAFAFA),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: borderLight,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: borderLight,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: darkGreen,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _viewModel.isLoading
                                      ? null
                                      : _handleForgotPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: darkGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shadowColor: Colors.black.withValues(
                                      alpha: 0.18,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _viewModel.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Kirim Link Reset ke Email  →',
                                          style: TextStyle(
                                            fontFamily: 'Lato',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 32),
                                const Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: borderLight),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'ATAU',
                                        style: TextStyle(
                                          fontFamily: 'Lato',
                                          fontSize: 12,
                                          color: Color(0xFFA0A7A0),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: borderLight),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Center(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    children: [
                                      const Text(
                                        'Ingat kata sandi Anda? ',
                                        style: TextStyle(
                                          fontFamily: 'Lato',
                                          fontSize: 14,
                                          color: textMuted,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => context.go('/login'),
                                        child: const Text(
                                          'Daftar/Masuk disini',
                                          style: TextStyle(
                                            fontFamily: 'Lato',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textDark,
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
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
