import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'konstanta.dart';
import 'model/pessanan.dart';
import 'resi_page.dart';

class HistoriPesananPage extends StatefulWidget {
  const HistoriPesananPage({Key? key}) : super(key: key);

  @override
  State<HistoriPesananPage> createState() => _HistoriPesananPageState();
}

class _HistoriPesananPageState extends State<HistoriPesananPage> {
  late Future<List<Pesanan>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<List<Pesanan>> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(Uri.parse('$baseUrl/pesananAdminApi'), headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'] as List;
      final list = data.map((e) => Pesanan.fromJson(e)).toList();
      // ambil hanya status 4 & 5 atau teks 'Pesanan diterima/selesai'
      var filtered = list.where((p) {
        final raw = p.status?.toString() ?? '';
        final code = int.tryParse(raw);
        if (code != null) {
          return code >= 4;
        }
        // fallback ke string
        return raw.toLowerCase().contains('selesai') || raw.toLowerCase().contains('diterima');
      }).toList();
      final type = prefs.getString('type');
      if (type == 'customer') {
        final userId = prefs.getInt('id');
        if (userId != null) {
          filtered = filtered.where((e) => e.idUser == userId).toList();
        }
      }
      return filtered;
    }
    throw Exception('Gagal memuat histori pesanan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histori Pesanan')),
      body: FutureBuilder<List<Pesanan>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) return const Center(child: Text('Belum ada histori pesanan'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final p = list[i];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage('$gambarUrl/produk/${p.fotoProduk ?? 'download.jpg'}')),
                title: Text(p.namaProduk ?? ''),
                trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ResiPage(idPesanan: p.idPesanan ?? 0)));
                    },
                    child: const Text('Lihat Resi'),
                  ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No. Resi: ${p.noResi?.isNotEmpty == true ? p.noResi : '-'}'),
                    if (p.name != null) Text('Pemesan: ${p.name}'),
                    Text('Jumlah: ${p.quantity} | Total: Rp ${p.hargaTotalBayar}'),
                    if (p.tipePembayaran != null) Text('Pembayaran: ${p.tipePembayaran}'),
                    if (p.createdAt != null) Text('Tgl: ' + (() {
                      final d = DateTime.parse(p.createdAt!).toLocal();
                      final datePart = '${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year}';
                      final timePart = '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}:${d.second.toString().padLeft(2,'0')}';
                      return '$datePart $timePart';
                    }())),
                    Text(
                      'Status: ' + (() {
                        final s = p.status?.toString() ?? '';
                        switch (s) {
                          case '4':
                            return 'Pesanan diterima';
                          case '5':
                            return 'Pesanan selesai';
                          default:
                            return s;
                        }
                      }()),
                      style: TextStyle(
                        color: (() {
                          final s = p.status?.toString() ?? '';
                          switch (s) {
                            case '4':
                              return Colors.amber;
                            case '5':
                              return Colors.grey;
                            default:
                              return Colors.black;
                          }
                        }()),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}