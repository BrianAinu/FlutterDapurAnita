import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'konstanta.dart';
import 'model/pessanan.dart';

class PesananPage extends StatefulWidget {
  const PesananPage({Key? key}) : super(key: key);

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  late Future<List<Pesanan>> futurePesanan;

  @override
  void initState() {
    super.initState();
    futurePesanan = fetchPesanan();
  }

  Future<void> _cancelPesanan(int idPesanan) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.post(
      Uri.parse('$baseUrl/pesanan/cancelApi'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'id_pesanan': idPesanan.toString()},
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan dibatalkan')));
      setState(() {
        futurePesanan = fetchPesanan();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membatalkan pesanan')));
    }
  }

  Future<List<Pesanan>> fetchPesanan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('id');
    final response = await http.get(
      Uri.parse(userId != null ? '$baseUrl/pesanan/indexApi?id_user=$userId' : '$baseUrl/pesanan/indexApi'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List items = decoded is List ? decoded : decoded['data'] ?? [];
      final list = items.map((e) => Pesanan.fromJson(e)).toList();
      // Tampilkan hanya pesanan dengan status < 3 (belum dikirim)
      return list.where((p) {
        final s = p.status?.toString() ?? '';
        final code = int.tryParse(s) ?? -1;
        return code < 3; // status 0,1,2
      }).toList();
    } else {
      throw Exception('Gagal memuat pesanan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: FutureBuilder<List<Pesanan>>(
        future: futurePesanan,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada pesanan'));
          }
          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = snapshot.data![index];
              final dateText = p.createdAt != null
                  ? ' | Tgl: '+ (() {
                      final d = DateTime.parse(p.createdAt!).toLocal();
                      final datePart = '${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year}';
                      final timePart = '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}:${d.second.toString().padLeft(2,'0')}';
                      return '$datePart $timePart';
                    }())
                  : '';

              return ListTile(
                leading: Image.network(
                  '$gambarUrl/produk/${p.fotoProduk ?? 'download.jpg'}',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(p.namaProduk ?? 'Pesanan #${p.idPesanan}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.name != null) Text('Pemesan: ${p.name}'),
                    Text('Jumlah: ${p.quantity} | Total: Rp ${p.hargaTotalBayar} | Pembayaran: ${p.tipePembayaran}$dateText'),
                    Text(
                      'Status: ${() {
                        final s = p.status?.toString() ?? '';
                        switch (s) {
                          case '0':
                            return 'Belum dikonfirmasi';
                          case '1':
                            return 'Sudah dikonfirmasi';
                          case '2':
                            return 'Pesanan dibuat';
                          case '3':
                            return 'Pesanan dikirim';
                          case '4':
                            return 'Pesanan diterima';
                          case '5':
                            return 'Pesanan selesai';
                          default:
                            return s;
                        }
                      }()} ',
                      style: TextStyle(
                        color: () {
                          final s = p.status?.toString() ?? '';
                          switch (s) {
                            case '0':
                              return Colors.orange;
                            case '1':
                              return Colors.green;
                            case '2':
                              return Colors.blue;
                            case '3':
                              return Colors.purple;
                            case '4':
                              return Colors.amber;
                            case '5':
                              return Colors.grey;
                            default:
                              return Colors.black;
                          }
                        }(),
                      ),
                    ),
                    if (p.buktiBayar != null)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: InteractiveViewer(
                                child: Image.network('$gambarUrl/bukti_bayar/${p.buktiBayar}', fit: BoxFit.contain),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Lihat bukti pembayaran',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Batalkan Pesanan'),
                        content: const Text('Yakin membatalkan pesanan?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c,false), child: const Text('Tidak')),
                          ElevatedButton(onPressed: () => Navigator.pop(c,true), child: const Text('Ya')),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    await _cancelPesanan(p.idPesanan!);
                    Navigator.pushReplacementNamed(context, '/keranjang');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
