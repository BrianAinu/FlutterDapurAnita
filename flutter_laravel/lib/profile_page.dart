import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'konstanta.dart';
import 'model/profil.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int? _userId;
  Future<Profil>? futureProfil;

  // controllers for edit
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _passC = TextEditingController();
  final _repassC = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureProfil = fetchProfil();
  }

  Future<Profil> fetchProfil() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    _userId = prefs.getInt('id');
    if (_userId == null) {
      throw Exception('ID user tidak ditemukan');
    }

    final res = await http.get(Uri.parse('$baseUrl/profileApi/$_userId'), headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return Profil.fromJson(data['data'] ?? {});
    }
    throw Exception('Gagal memuat profil');
  }

  Future<void> updateProfil() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final body = {
      'name': _nameC.text,
      'email': _emailC.text,
      'hp': _phoneC.text,
    };

    final res = await http.put(Uri.parse('$baseUrl/profileApi/$_userId'), headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    }, body: json.encode(body));

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
      setState(() {
        futureProfil = fetchProfil();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui profil')));
    }
  }

  Future<void> changePassword() async {
    if (_passC.text.isEmpty || _repassC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi password')));
      return;
    }
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.put(
      Uri.parse('$baseUrl/profilePasswordApi/$_userId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'password': _passC.text,
        'repassword': _repassC.text,
      }),
    );

    if (res.statusCode == 200) {
      Navigator.pop(context); // close dialog
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password diubah')));
      _passC.clear();
      _repassC.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal ubah password')));
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _passC.dispose();
    _repassC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<Profil>(
        future: futureProfil,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada data profil'));
          }

          final profil = snapshot.data!;
          _userId = profil.id;
          _nameC.text = profil.name ?? '';
          _emailC.text = profil.email ?? '';
          _phoneC.text = profil.hp ?? '';


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    profil.photo != null && profil.photo!.isNotEmpty
                        ? '$gambarUrl/foto_profil/${profil.photo}'
                        : 'https://ui-avatars.com/api/?name=${profil.name ?? 'U'}',
                  ),
                ),
                const SizedBox(height: 8),
                Text(profil.type ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameC,
                  decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailC,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneC,
                  decoration: const InputDecoration(labelText: 'No. HP', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: updateProfil,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Simpan'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Ganti Password'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _passC,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Password Baru'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _repassC,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Ulangi Password'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                          ElevatedButton(onPressed: changePassword, child: const Text('Simpan')),
                        ],
                      ),
                    );
                  },
                  child: const Text('Ganti Password'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}