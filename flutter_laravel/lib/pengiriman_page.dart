import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'konstanta.dart';
import 'model/pessanan.dart';
import 'resi_page.dart';

class PengirimanPage extends StatefulWidget {
  const PengirimanPage({Key? key}) : super(key: key);

  @override
  State<PengirimanPage> createState() => _PengirimanPageState();
}

class _PengirimanPageState extends State<PengirimanPage> {
  late Future<List<Pesanan>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<List<Pesanan>> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(Uri.parse('$baseUrl/pengirimanAdminApi'), headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'] as List;
      final all = data.map((e) => Pesanan.fromJson(e)).toList();
      // tampilkan hanya status 3 (pesanan dikirim)
      final list = all.where((p){
        final raw = p.status?.toString() ?? '';
        final code = int.tryParse(raw);
        if(code!=null){
          return code==3;
        }
        return raw.toLowerCase().contains('dikirim');
      }).toList();
      // jika userId tersimpan (customer), filter agar hanya pesanan miliknya
      final type = prefs.getString('type');
      if (type == 'customer') {
        final userId = prefs.getInt('id');
        if (userId != null) {
          return list.where((e) => e.idUser == userId).toList();
        }
      }
      return list;
    }
    throw Exception('Gagal memuat pengiriman');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengiriman')),
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
          if (list.isEmpty) return const Center(child: Text('Tidak ada pesanan dikirim'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final p = list[i];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage('$gambarUrl/produk/${p.fotoProduk ?? 'download.jpg'}')),
                title: Text(p.namaProduk ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No. Resi: ${p.noResi?.isNotEmpty == true ? p.noResi : '-'}'),
                    Text('Pemesan: ${ (p.name == null || p.name!.toLowerCase() == 'null' || p.name!.trim().isEmpty) ? '-' : p.name }'),
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
                          case '3':
                            return 'Pesanan dikirim';
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
                            case '3':
                              return Colors.purple;
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
                    if (p.alamatLengkap != null) ...[
                      Text(p.alamatLengkap!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${p.namaKota ?? ''}, ${p.namaProv ?? ''}'),
                    ]
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ResiPage(idPesanan: p.idPesanan ?? 0)));
                  },
                  child: const Text('Lihat Resi'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
