import 'package:flutter/material.dart';

import 'package:app/features/auth/data/repositories/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
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

    setState(() => _isLoading = true);
    try {
      await AuthService.forgotPassword(email: email);
      if (!mounted) return;

      setState(() => _isLoading = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Instruksi Reset'),
          content: const Text(
            'Jika alamat email terdaftar, instruksi untuk mengatur ulang kata sandi telah dikirim.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Ke Halaman Login'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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

    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  const Text(
                    'MUSEUM BRAWIJAYA',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: darkGreen,
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
                                  'Masukkan email akun Anda. Kami akan mengirimkan petunjuk untuk mengatur ulang kata sandi Anda.',
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
                                  onPressed: _isLoading
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
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Kirim Instruksi Reset  →',
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
                                        onTap: () => Navigator.pop(context),
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
  }
}
