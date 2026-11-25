import 'package:flutter/material.dart';
import 'package:app/features/auth/data/repositories/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _namaController;
  late final TextEditingController _emailController;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _namaController = TextEditingController(text: user?.nama ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final nama = _namaController.text.trim();
    final email = _emailController.text.trim();
    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;

    if (nama.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan email wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }

    if (newPass.isNotEmpty && newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi baru minimal 6 karakter'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.updateProfile(
        userId: user.id,
        nama: nama,
        email: email,
        currentPassword: currentPass.isNotEmpty ? currentPass : null,
        newPassword: newPass.isNotEmpty ? newPass : null,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
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

    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar header
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (user?.nama.isNotEmpty == true ? user!.nama[0].toUpperCase() : 'U'),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: goldAccent,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: goldAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.nama ?? 'Pengguna',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
              Text(
                user?.email ?? '',
                style: const TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 24),

              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Lengkap',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _namaController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Alamat Email',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),

                    const Text(
                      'Ubah Kata Sandi (Opsional)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kosongkan jika tidak ingin mengubah kata sandi',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Kata Sandi Saat Ini',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Masukkan kata sandi lama',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA0A7A0)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18, color: textMuted),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Kata Sandi Baru',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Minimal 6 karakter',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA0A7A0)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 18, color: textMuted),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
}

