import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_laravel/konstanta.dart';

class HapusProduk extends StatefulWidget {
  final String idBarang;
  const HapusProduk({super.key, required this.idBarang});

  @override
  State<HapusProduk> createState() => _HapusProdukState();
}

class _HapusProdukState extends State<HapusProduk> {
  bool _isDeleting = false;

  Future<void> _deleteProduk() async {
    setState(() => _isDeleting = true);
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/deleteApi/${widget.idBarang}'),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil dihapus')));
        Navigator.pop(context, true); // return true to refresh list
      } else {
        throw Exception('Gagal menghapus produk');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hapus Produk')),
      body: Center(
        child: _isDeleting
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Apakah Anda yakin ingin menghapus produk ini?',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _deleteProduk,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                          child: const Text('Hapus'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        )
                      ],
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
