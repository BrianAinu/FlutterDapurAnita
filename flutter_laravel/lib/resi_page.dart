import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'konstanta.dart';
import 'model/pessanan.dart';
import 'model/alamat.dart';

class ResiPage extends StatelessWidget {
  final int idPesanan;
  const ResiPage({Key? key, required this.idPesanan}) : super(key: key);

  Future<Map<String, dynamic>> fetchInvoice() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final res = await http.get(Uri.parse('$baseUrl/resiApi/$idPesanan'), headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      final pesanan = Pesanan.fromJson(data);
      Alamat? alamat;
      if (pesanan.alamatLengkap == null || pesanan.alamatLengkap!.isEmpty) {
        final alamatRes = await http.get(Uri.parse('$baseUrl/alamatApi/${pesanan.idUser}'), headers: {
          'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token',
        });
        if (alamatRes.statusCode == 200) {
          final list = json.decode(alamatRes.body)['data'] as List;
          if (list.isNotEmpty) alamat = Alamat.fromJson(list.first);
        }
      }
      return {'pesanan': pesanan, 'alamat': alamat};
    }
    throw Exception('Data tidak ditemukan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Resi')),
      body: FutureBuilder<Map<String,dynamic>>(
        future: fetchInvoice(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final p = snapshot.data!['pesanan'] as Pesanan;
          final alamat = snapshot.data!['alamat'] as Alamat?;
          final int qty = p.quantity ?? 1;
          final int hargaSatuan = p.hargaProduk ?? ((p.hargaTotalBayar ?? 0) ~/ qty);
          final int subtotal = hargaSatuan * qty;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text('DAPUR ANITA',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                ),
                const SizedBox(height: 2),
                const Center(
                  child: Text('INVOICE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Invoice No.'),
                      Text('#${p.idPesanan}',
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Tanggal'),
                      Text(p.createdAt ?? '')
                    ])
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dikirim Kepada:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(alamat?.namaPenerima ?? p.name ?? '-'),
                      if (alamat != null) ...[
                        Text(alamat.alamatLengkap),
                        Text('${alamat.namaKota}, ${alamat.namaProv}'),
                        Text(alamat.noTelp),
                      ] else if (p.alamatLengkap != null) ...[
                        Text(p.alamatLengkap!),
                        Text('${p.namaKota ?? ''}, ${p.namaProv ?? ''}'),
                        Text(p.noTelp ?? ''),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Detail Produk:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                        decoration: BoxDecoration(color: Colors.blue.shade50),
                        children: const [
                          Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('Produk',
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('Qty',
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('Harga',
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('Subtotal',
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                        ]),
                    TableRow(children: [
                      Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(p.namaProduk ?? '')),
                      Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text('$qty')),
                      Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text('Rp $hargaSatuan')),
                      Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text('Rp $subtotal')),
                    ])
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Rp ${p.hargaTotalBayar}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent))
                  ],
                ),
                const SizedBox(height: 12),
                Text('Metode Pembayaran: ${p.tipePembayaran ?? '-'}')
              ],
            ),
          );
        },
      ),
    );
  }
}
