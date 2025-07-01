import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'konstanta.dart';
import 'model/alamat.dart';

class AlamatPage extends StatefulWidget {
  const AlamatPage({Key? key}) : super(key: key);

  @override
  State<AlamatPage> createState() => _AlamatPageState();
}

class _AlamatPageState extends State<AlamatPage> {
  Future<List<Alamat>>? futureAlamat;
  int? _userId;

  // form controllers
  final _namaC = TextEditingController();
  final _telpC = TextEditingController();
  final _alamatC = TextEditingController();
  final _kodePosC = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureAlamat = fetchAlamat();
  }

  Future<List<Alamat>> fetchAlamat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    _userId = prefs.getInt('id');
    if (_userId == null) throw Exception('ID user tidak ditemukan');

    final res = await http.get(Uri.parse('$baseUrl/alamatApi/$_userId'), headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      List listJson = data['data'] ?? [];
      return listJson.map((e) => Alamat.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat alamat');
  }

  // delete address
  Future<void> _hapusAlamat(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.delete(Uri.parse('$baseUrl/alamatDeleteApi/$id'), headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alamat dihapus')));
      setState(() {
        futureAlamat = fetchAlamat();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus alamat')));
    }
  }

  Future<void> _updateAlamat(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final body = {
      'nama_penerima': _namaC.text,
      'no_telp': _telpC.text,
      'alamat_lengkap': _alamatC.text,
      'kode_pos': _kodePosC.text,
    };
    final res = await http.put(Uri.parse('$baseUrl/alamatUpdateApi/$id'), headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    }, body: json.encode(body));
    if (res.statusCode == 200) {
      Navigator.pop(context);
      setState(() { futureAlamat = fetchAlamat(); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alamat diperbarui')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui alamat')));
    }
  }

  Future<void> _simpanAlamat() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final body = {
      'id_user': _userId.toString(),
      'nama_penerima': _namaC.text,
      'no_telp': _telpC.text,
      'alamat_lengkap': _alamatC.text,
      'kode_pos': _kodePosC.text,
      // Untuk sederhana, provinsi & kota diisi dummy 0
      'id_provinsi': '0',
      'nama_prov': '-',
      'id_kota': '0',
      'nama_kota': '-',
    };

    final res = await http.post(Uri.parse('$baseUrl/alamatStoreApi'), headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    }, body: json.encode(body));

    if (res.statusCode == 200 || res.statusCode == 201) {
      Navigator.pop(context);
      setState(() {
        futureAlamat = fetchAlamat();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alamat tersimpan')));
      _namaC.clear();
      _telpC.clear();
      _alamatC.clear();
      _kodePosC.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal simpan alamat')));
    }
  }

  void _showForm({Alamat? edit}) {
    // preload values if edit
    if (edit != null) {
      _namaC.text = edit.namaPenerima;
      _telpC.text = edit.noTelp;
      _alamatC.text = edit.alamatLengkap;
      _kodePosC.text = edit.kodePos;
    } else {
      _namaC.clear();
      _telpC.clear();
      _alamatC.clear();
      _kodePosC.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(edit == null ? 'Tambah Alamat' : 'Edit Alamat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _namaC, decoration: const InputDecoration(labelText: 'Nama Penerima')),
              const SizedBox(height: 8),
              TextField(controller: _telpC, decoration: const InputDecoration(labelText: 'No. Telp')),
              const SizedBox(height: 8),
              TextField(controller: _alamatC, decoration: const InputDecoration(labelText: 'Alamat Lengkap')),
              const SizedBox(height: 8),
              TextField(controller: _kodePosC, decoration: const InputDecoration(labelText: 'Kode Pos')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () async {
            if (edit == null) {
              await _simpanAlamat();
            } else {
              await _updateAlamat(edit.id);
            }
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Alamat')),
      body: FutureBuilder<List<Alamat>>(
        future: futureAlamat,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada alamat'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final a = list[i];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(a.alamatLengkap),
                subtitle: Text('${a.namaKota}, ${a.namaProv} - ${a.kodePos}\n${a.namaPenerima} | ${a.noTelp}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showForm(edit: a),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Hapus Alamat'),
                            content: const Text('Yakin menghapus alamat ini?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                              ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus')),
                            ],
                          ),
                        );
                        if (ok == true) await _hapusAlamat(a.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
