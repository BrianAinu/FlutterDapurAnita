import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_laravel/model/kategori.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_laravel/konstanta.dart';
import 'package:flutter_laravel/model/produk.dart';

// Helper function to add headers for Laravel API
Map<String, String> getApiHeaders() {
  return {
    'Accept': 'application/json',
    'Content-Type': 'multipart/form-data',
  };
}

class AddProduk extends StatefulWidget {
  const AddProduk({super.key});

  @override
  State<AddProduk> createState() => _AddProdukState();
}

class _AddProdukState extends State<AddProduk> {
  final _formKey = GlobalKey<FormState>();
  final namaController = TextEditingController();
  // Kategori
  List<Kategori> _kategoriList = [];
  Kategori? _selectedKategori;
  final kategoriController = TextEditingController(); // will hold id_kategori
  final beratController = TextEditingController();
  final stokController = TextEditingController();
  final hargaController = TextEditingController();
  final deskripsiController = TextEditingController();

  void clearForm() {
    namaController.clear();
    kategoriController.clear();
    beratController.clear();
    stokController.clear();
    hargaController.clear();
    deskripsiController.clear();
    _image = null;
  }

  @override
  void initState() {
    super.initState();
    getCategories();
  }

  Future<void> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/kategoriApi'), headers: {
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _kategoriList = data.map((e) => Kategori.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    namaController.dispose();
    kategoriController.dispose();
    beratController.dispose();
    stokController.dispose();
    hargaController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }

  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> addProduk() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/storeApi'));
        
        // Add image if selected
        if (_image != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'img1',
            _image!.path,
          ));
        }

        // Add form data
        request.fields['nama_produk'] = namaController.text;
        request.fields['kategori_produk'] = kategoriController.text;
        request.fields['berat_produk'] = beratController.text;
        request.fields['stok_produk'] = stokController.text;
        request.fields['harga_produk'] = hargaController.text;
        request.fields['deskripsi_produk'] = deskripsiController.text;

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        
        if (response.statusCode == 200) {
          if (!mounted) return;
          // Kembalikan nilai true agar halaman sebelumnya bisa refresh
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil ditambahkan')),
          );
          
        } else {
          String errorMessage;
          try {
            var errorData = json.decode(responseData);
            errorMessage = errorData['message'] ?? 'Gagal menambahkan produk';
          } catch (e) {
            errorMessage = 'Error: ${response.statusCode} - ${responseData.substring(0, 100)}...';
          }
          throw Exception(errorMessage);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: namaController,
                decoration: const InputDecoration(labelText: "Nama Produk"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan nama produk';
                  }
                  return null;
                },
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
                validator: (val) {
                  if (val == null) {
                    return 'Silakan pilih kategori';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: beratController,
                decoration: const InputDecoration(labelText: "Berat"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan berat produk';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Berat harus berupa angka positif';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: stokController,
                decoration: const InputDecoration(labelText: "Stok"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan stok';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Stok harus berupa angka positif';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: hargaController,
                decoration: const InputDecoration(labelText: "Harga"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Silakan masukkan harga produk';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Harga harus berupa angka positif';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Nasi goreng dengan ayam dan telur',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              if (_image != null)
                Image.file(
                  _image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: getImage,
                child: Text('Pilih Gambar'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: addProduk,
                    child: const Text('Tambah'),
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
      ),
    );
  }
}