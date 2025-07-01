import 'package:flutter/material.dart';
import 'package:flutter_laravel/konstanta.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_laravel/login/form_login.dart';

class PageRegister extends StatefulWidget {
  const PageRegister({super.key});

  @override
  State<PageRegister> createState() => _PageRegisterState();
}

class _PageRegisterState extends State<PageRegister> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showAlert('Peringatan', 'Semua field harus diisi.');
      return;
    }

    if (password.length < 6) {
      _showAlert('Peringatan', 'Password minimal 6 karakter sesuai validasi server.');
      return;
    }

    
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('$baseUrl/registerApi');
      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': name,
          'email': email,
          'password': password,
                  },
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // registration successful
        _showAlert('Berhasil', 'Registrasi berhasil, silakan login.', onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PageLogin()),
          );
        });
      } else {
        String message = 'Registrasi gagal';
        try {
          final data = json.decode(response.body);
          if (data is Map && data.containsKey('message')) {
            message = data['message'];
          }
        } catch (_) {}
        if (response.statusCode == 422) {
          // validation errors
          String errors = '';
          final data = json.decode(response.body);
          if (data is Map && data['errors'] is Map) {
            (data['errors'] as Map<String, dynamic>).forEach((key, value) {
              errors += '$key: ${(value as List).join(', ')}\n';
            });
          }
          _showAlert('Validasi', errors.isEmpty ? message : errors);
          return;
        }
        _showAlert('Gagal', message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showAlert('Error', 'Terjadi kesalahan: $e');
    }
  }

  void _showAlert(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
              if (onOk != null) onOk();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
                        const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Daftar'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PageLogin()),
                );
              },
              child: const Text('Sudah punya akun? Login'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
        super.dispose();
  }
}
