import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'konstanta.dart';
import 'model/keranjang.dart';
import 'pesanan_page.dart';

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({Key? key}) : super(key: key);

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  late Future<List<KeranjangItem>> futureCart;
  File? _selectedImage;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    futureCart = fetchKeranjang();
  }

  Future<List<KeranjangItem>> fetchKeranjang() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id');
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse(userId != null ? '$baseUrl/keranjang/indexApi?id_user=$userId' : '$baseUrl/keranjang/indexApi'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    debugPrint('KERANJANG status: \\${response.statusCode}');
    debugPrint('KERANJANG body: \\${response.body.substring(0, math.min(300, response.body.length))}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        items = decoded['data'] as List;
      } else if (decoded is Map && decoded.containsKey('keranjang')) {
        items = decoded['keranjang'] as List;
      } else {
        throw Exception('Format data keranjang tidak dikenali');
      }
      return items.map((e) => KeranjangItem.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat keranjang');
    }
  }

  Future<void> updateQty(int idKeranjang, int newQty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      debugPrint('UPDATE qty $idKeranjang -> $newQty');
      debugPrint('PUT qty id=$idKeranjang new=$newQty');
      final response = await http.put(
        Uri.parse('$baseUrl/keranjang/updateApi/$idKeranjang'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'quantity': newQty.toString(),
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          futureCart = fetchKeranjang();
        });
      }
    } catch (_) {}
  }

  Future<void> deleteItem(int idKeranjang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      debugPrint('DELETE item id=$idKeranjang');
      final response = await http.delete(
        Uri.parse('$baseUrl/keranjang/deleteApi/$idKeranjang'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          futureCart = fetchKeranjang();
        });
      }
    } catch (_) {}
  }

  Future<void> confirmDelete(int idKeranjang) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus item'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      deleteItem(idKeranjang);
    }
  }

  Future<void> checkoutCart(List<KeranjangItem> items, {File? buktiBayar}) async {
    if (items.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memproses checkout...')));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      int success = 0;
      for (final item in items) {
        if (item.id == null) continue;
        late http.Response response;
        if (buktiBayar != null) {
          // kirim gambar untuk setiap pesanan
          final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/pesanan/storeApi'))
            ..fields['id_keranjang'] = item.id.toString()
            ..fields['tipe_pembayaran'] = 'lunas'
            ..headers.addAll({
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            });
          request.files.add(await http.MultipartFile.fromPath('bukti_bayar', buktiBayar.path));
          final streamed = await request.send();
          response = await http.Response.fromStream(streamed);
        } else {
          response = await http.post(
          Uri.parse('$baseUrl/pesanan/storeApi'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'id_keranjang': item.id.toString(),
            'tipe_pembayaran': 'lunas',
          },
        );
        }
        if (response.statusCode == 201 || response.statusCode == 200) {
          success++;
        } else {
          debugPrint('Checkout gagal ${response.body}');
        }
      }

      // selesai loop
      if (success > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$success pesanan berhasil dibuat')));
        setState(() {
          futureCart = fetchKeranjang(); // refresh keranjang
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PesananPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout gagal')));
      }
    } catch (e) {
      debugPrint('Checkout error $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _checkoutWithSelectedImage(List<KeranjangItem> items) async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan tambahkan bukti pembayaran terlebih dahulu')),
      );
      return;
    }
    await checkoutCart(items, buktiBayar: _selectedImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: FutureBuilder<List<KeranjangItem>>(
        future: futureCart,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keranjang kosong'));
          }

          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          '$gambarUrl/produk/${item.fotoProduk ?? 'download.jpg'}',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 70,
                          child: Text(
                            item.namaProduk ?? '',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Rp ${item.hargaProduk}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: (item.id != null && item.qty != null && item.qty! > 1)
                              ? () => updateQty(item.id!, item.qty! - 1)
                              : null,
                        ),
                        Text(item.qty?.toString() ?? '0'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: item.id != null
                              ? () => updateQty(item.id!, (item.qty ?? 0) + 1)
                              : null,
                        ),
                        Checkbox(
                          value: _selectedIds.contains(item.id),
                          onChanged: item.id == null
                              ? null
                              : (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedIds.add(item.id!);
                                    } else {
                                      _selectedIds.remove(item.id);
                                    }
                                  });
                                },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: item.id != null ? () => confirmDelete(item.id!) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<List<KeranjangItem>>(
        future: futureCart,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }
          final selected = snapshot.data!.where((e) => _selectedIds.contains(e.id)).toList();
          final total = selected
              .map((e) => (e.hargaProduk ?? 0) * (e.qty ?? 0))
              .fold<int>(0, (a, b) => a + b);
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage == null
                        ? const Center(child: Text('Tambahkan Bukti Bayar'))
                        : Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                      if(selected.isEmpty){
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih item yang akan di-checkout')));
                        return;
                      }
                      _checkoutWithSelectedImage(selected);
                    },
                  child: Text('Checkout (Rp $total)'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
