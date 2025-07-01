import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_laravel/model/kategori.dart';
import 'package:flutter_laravel/konstanta.dart';

class EditForm extends StatefulWidget {
  const EditForm({super.key, this.idBarang});
  final String? idBarang;

  @override
  State<EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<EditForm> {
  String? id;
  String? gambar;
  File? _pickedImage;

  TextEditingController namaController = TextEditingController();
  TextEditingController kategoriController = TextEditingController();
  List<Kategori> _kategoriList = [];
  Kategori? _selectedKategori;
  TextEditingController beratController = TextEditingController();
  TextEditingController stokController = TextEditingController();
  TextEditingController hargaProdukController = TextEditingController();
  TextEditingController deskripsiProdukController = TextEditingController();

  @override
  void initState() {
    super.initState();
    id = widget.idBarang;
    if (id != null) {
      ambilDataEdit(id!);
    }
    getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Barang"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: namaController,
              decoration: const InputDecoration(labelText: "Nama Produk"),
            ),
            DropdownButtonFormField<Kategori>(
              value: _selectedKategori,
              items: _kategoriList
                  .map((k) => DropdownMenuItem<Kategori>(
                        value: k,
                        child: Text(k.nama),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedKategori = val;
                  kategoriController.text = val?.id.toString() ?? '';
                });
              },
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            TextFormField(
              controller: beratController,
              decoration: const InputDecoration(labelText: "Berat"),
            ),
            TextFormField(
              controller: stokController,
              decoration: const InputDecoration(labelText: "Stok"),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: hargaProdukController,
              decoration: const InputDecoration(labelText: "Harga"),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: deskripsiProdukController,
              decoration: const InputDecoration(labelText: "Deskripsi"),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_pickedImage != null)
              Image.file(
                _pickedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else if (gambar != null)
              Image.network(
                '$gambarUrl/produk/$gambar',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text('Pilih Gambar Baru'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => onSubmit(id!),
                  child: const Text('Simpan'),
                ),
                ElevatedButton(
                  onPressed: clearForm,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/kategoriApi'), headers: {
        'Accept': 'application/json',
      });
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _kategoriList = data.map((e) => Kategori.fromJson(e)).toList();
          // after list ready, try select existing id
          if (kategoriController.text.isNotEmpty) {
            final idKat = int.tryParse(kategoriController.text);
            if (idKat != null) {
              if (_kategoriList.isNotEmpty) {
                _selectedKategori = _kategoriList.firstWhere(
                  (k) => k.id == idKat,
                  orElse: () => _kategoriList.first,
                );
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> ambilDataEdit(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/editApi/$id'));

    if (response.statusCode == 200) {
      final user = json.decode(response.body)['user'];
      setState(() {
        namaController.text = user['nama_produk'];
        kategoriController.text = user['id_kategori'].toString();
        // set selected if list already fetched
        final idKat = int.tryParse(kategoriController.text);
        if (_kategoriList.isNotEmpty && idKat != null) {
          _selectedKategori = _kategoriList.firstWhere(
            (k) => k.id == idKat,
            orElse: () => _kategoriList.first,
          );
        }
        beratController.text = user['berat'];
        stokController.text = user['stok'].toString();
        hargaProdukController.text = user['harga_produk'].toString();
        deskripsiProdukController.text = user['deskripsi_produk'];
        gambar = user['foto_produk'];
      });
    } else {
      throw Exception('Gagal memuat data produk');
    }
  }

  Future<void> onSubmit(String id) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/updateApi/$id'));
    request.fields['_method'] = 'PUT';
    request.fields['nama_produk'] = namaController.text;
    request.fields['kategori_produk'] = kategoriController.text;
    request.fields['berat_produk'] = beratController.text;
    request.fields['stok_produk'] = stokController.text;
    request.fields['harga_produk'] = hargaProdukController.text;
    request.fields['deskripsi_produk'] = deskripsiProdukController.text;

    if (_pickedImage != null) {
      // send empty img1 field so first if(\$request->img1!="") is false, forcing hasFile branch
      request.fields['img1'] = '';
      request.files.add(await http.MultipartFile.fromPath('img1', _pickedImage!.path));
    } else if (gambar != null) {
      request.fields['foto_lama'] = gambar!;
    }

    var streamed = await request.send();
    var respStr = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Pesan'),
          content: Text('Data berhasil disimpan. Silakan kembali ke menu utama.'),
        ),
      );
    } else {
      throw Exception('Gagal mengupdate data: $respStr');
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  void clearForm() {
    namaController.clear();
    kategoriController.clear();
    beratController.clear();
    stokController.clear();
    hargaProdukController.clear();
    deskripsiProdukController.clear();
  }
}
