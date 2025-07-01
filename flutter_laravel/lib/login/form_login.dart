import 'package:flutter_laravel/home_page.dart';
import 'package:flutter_laravel/konstanta.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_laravel/register/form_register.dart';
import 'package:flutter_laravel/home_page.dart';

class PageLogin extends StatefulWidget {
  const PageLogin({super.key});

  @override
  State<PageLogin> createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login(String email, String password) async {
    try {
      print("Attempting login with email: $email");

      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        body: {"email": email, "password": password},
      );

      if (response.statusCode == 200) {
        //mengambil data token
        //final token = json.decode(response.body)['token'];
        //mengabil data user
        final user = json.decode(response.body)['user'];
        //menyimpan data token
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id', user['id']);
        await prefs.setString('name', user['name']);
        await prefs.setString('email', user['email']);
        await prefs.setString('type', user['type']);
        int? id = user['id'];
        String? name = user['name'];
        String? email = user['email'];
        String? type = user['type'];
        //berpindah halaman
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(id: id, name: name, email: email, type: type),
          ),
          (route) => false,
        );
      } else {
        AlertDialog alert = AlertDialog(
          title: Text("Login Gagal"),
          content: Container(child: Text("Username atau Password Salah")),
          actions: [
            TextButton(
              child: Text('Ok'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
        showDialog(context: context, builder: (context) => alert);
      }
    } catch (e) {
      print("Error during login: $e");
      AlertDialog alert = AlertDialog(
        title: Text("Error"),
        content: Container(child: Text("Terjadi kesalahan: $e")),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Ok"),
          ),
        ],
      );
      showDialog(context: context, builder: (context) => alert);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selamat Datang Di Dapur Anita"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFFE0B2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Text("Welcome 👋", style: TextStyle(fontSize: 24)),
            Text("Login Started!"),
            SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                login(emailController.text, passwordController.text);
              },
              child: const Text("Login"),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PageRegister()),
                );
              },
              child: const Text('Belum punya akun? Daftar'),
            ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}