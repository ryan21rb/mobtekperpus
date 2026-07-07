import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/users.dart';
import 'register_screen.dart';
import 'materi_screen.dart';
import 'user_screen.dart';
import 'petugas_screen.dart';

import '../utils/custom_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscureText = true;

  // State untuk menyimpan tipe login yang dipilih (Default: user)
  String _selectedRole = 'user';

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      User? user = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        // Validasi: Memastikan role di database cocok dengan role yang dipilih di UI
        if (user.role != _selectedRole) {
          _showErrorSnackBar(
            'Akun Anda tidak terdaftar sebagai $_selectedRole!',
          );
          return;
        }

        // Logika Navigasi Berdasarkan Pilihan Role
        if (_selectedRole == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MateriScreen(),
            ), // DISINI PERBAIKANNYA (Menyesuaikan dengan import materi_screen.dart)
          );
        } else if (_selectedRole == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserScreen()),
          );
        } else if (_selectedRole == 'petugas') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PetugasScreen()),
          );
        }
      } else {
        _showErrorSnackBar(
          'Login Gagal! Email/Password salah atau koneksi bermasalah.',
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    CustomToast.show(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 70),
                        // Logo / Icon Aplikasi
                        Center(
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A237E), Color(0xFF0A0E2E)], // Premium Blue Indigo Gradient
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.library_books,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            "Perpus",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            "Silahkan masuk untuk melanjutkan",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 30),
  
                        // Pilihan Tipe Login
                        const Text(
                          "Masuk Sebagai",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return const Color(0xFF1A237E);
                                    }
                                    return Colors.white;
                                  }),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white;
                                    }
                                    return Colors.grey.shade600;
                                  }),
                              side: WidgetStateProperty.all(BorderSide(color: Colors.grey.shade300)),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                value: 'user',
                                label: Text('User'),
                                icon: Icon(Icons.person_outline, size: 18),
                              ),
                              ButtonSegment<String>(
                                value: 'admin',
                                label: Text('Admin'),
                                icon: Icon(
                                  Icons.admin_panel_settings_outlined,
                                  size: 18,
                                ),
                              ),
                              ButtonSegment<String>(
                                value: 'petugas',
                                label: Text('Petugas'),
                                icon: Icon(Icons.badge_outlined, size: 18),
                              ),
                            ],
                            selected: <String>{_selectedRole},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedRole = newSelection.first;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
  
                        // Input Email
                        const Text(
                          "Email Address",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'user@email.com',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                            ),
                            validator: (value) => (value == null || value.isEmpty)
                                ? 'Email wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Input Password
                          const Text(
                            "Password",
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureText = !_obscureText),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.length < 6)
                                ? 'Password minimal 6 karakter'
                                : null,
                          ),
                          const SizedBox(height: 40),

                          // Tombol Login
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A237E), Color(0xFF0A0E2E)], // Premium Blue Indigo Gradient
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Link Menuju Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Belum punya akun? ",
                                style: TextStyle(color: Colors.black87),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Daftar Sekarang",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
    );
  }
}
