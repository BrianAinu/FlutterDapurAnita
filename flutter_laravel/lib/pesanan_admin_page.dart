import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_laravel/konstanta.dart';
import 'package:flutter_laravel/model/pessanan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PesananAdminPage extends StatefulWidget {
  const PesananAdminPage({Key? key}) : super(key: key);

  @override
  State<PesananAdminPage> createState() => _PesananAdminPageState();
}

class _PesananAdminPageState extends State<PesananAdminPage> {
  String _statusText(int s) {
    switch (s) {
      case 0:
        return 'Belum dikonfirmasi';
      case 1:
        return 'Sudah dikonfirmasi';
      case 2:
        return 'Pesanan dibuat';
      case 3:
        return 'Pesanan dikirim';
      case 4:
        return 'Pesanan diterima';
      case 5:
        return 'Pesanan selesai';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(int s) {
    switch (s) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.amber;
      case 5:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
  late Future<List<Pesanan>> futurePesanan;

  @override
  void initState() {
    super.initState();
    futurePesanan = fetchPesanan();
  }

  Future<List<Pesanan>> fetchPesanan() async {
        final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(
      Uri.parse('$baseUrl/pesananAdminApi'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body)['data'] ?? jsonDecode(res.body);
      return data.map((e) => Pesanan.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat pesanan');
  }

  Future<void> kirimPesanan(String id, String noResi) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.post(Uri.parse('$baseUrl/pesananAdminKirimApi'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({'id_pesanan': id, 'no_resi': noResi}));
    if (res.statusCode == 200) {
      setState(() {
        futurePesanan = fetchPesanan();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal kirim pesanan')));
    }
  }

  Future<void> ubahStatus(String id, int status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.put(
      Uri.parse('$baseUrl/pesananAdminStatusApi/$id/$status'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      setState(() {
        futurePesanan = fetchPesanan();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal ubah status')));
    }
  }

  Future<void> konfirmasiPesanan(String id) async {
    final res = await http.put(Uri.parse('$baseUrl/pesananAdminKonfirmasiApi/$id'), headers: {
      'Accept': 'application/json',
    });
    if (res.statusCode == 200) {
      setState(() {
        futurePesanan = fetchPesanan();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal konfirmasi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Admin')),
      body: FutureBuilder<List<Pesanan>>(
        future: futurePesanan,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada pesanan'));
          }
          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final p = snapshot.data![index];
              final dateText = p.createdAt != null
                  ? ' | Tgl: ' + (() {
                      final d = DateTime.parse(p.createdAt!).toLocal();
                      final datePart = '${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year}';
                      final timePart = '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}:${d.second.toString().padLeft(2,'0')}';
                      return '$datePart $timePart';
                    }())
                  : '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage('$gambarUrl/produk/${p.fotoProduk ?? 'download.jpg'}'),
                ),
                title: Text(p.namaProduk ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.name != null) Text('Pemesan: ${p.name}'),
                    Text('Jumlah: ${p.quantity} | Total: Rp ${p.hargaTotalBayar} | Pembayaran: ${p.tipePembayaran}$dateText'),
                    Text(
                      'Status: ${_statusText(int.tryParse(p.status.toString()) ?? 0)}',
                      style: TextStyle(color: _statusColor(int.tryParse(p.status.toString()) ?? 0)),
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
                        child: const Text('Lihat bukti pembayaran', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                      ),
                  ],
                ),
                isThreeLine: true,
                trailing: DropdownButton<int>(
                  value: int.tryParse(p.status.toString()) ?? 0,
                  underline: const SizedBox(),
                  items: List.generate(6, (i) => DropdownMenuItem(value: i, child: Text(_statusText(i)))),
                  onChanged: (int? val) async {
                    if (val == null) return;
                    if (val == 3) {
                      final controller = TextEditingController();
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Input No. Resi'),
                          content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'No. Resi')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
                          ],
                        ),
                      );
                      if (ok == true && controller.text.trim().isNotEmpty) {
                        await kirimPesanan(p.idPesanan.toString(), controller.text.trim());
                      }
                    } else {
                      await ubahStatus(p.idPesanan.toString(), val);
                    }
                    if (val != null) {
                      ubahStatus(p.idPesanan.toString(), val);
                    }
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
