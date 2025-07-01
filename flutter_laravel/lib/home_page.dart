import 'package:flutter_laravel/login/form_login.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_laravel/konstanta.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_laravel/model/produk.dart';
import 'package:flutter_laravel/admin/tambah_produk.dart';
import 'package:flutter_laravel/admin/edit_produk.dart';
import 'package:flutter_laravel/admin/hapus_produk.dart';
import 'package:flutter_laravel/keranjang_page.dart';
import 'package:flutter_laravel/pesanan_page.dart';
import 'package:flutter_laravel/pesanan_admin_page.dart';
import 'package:flutter_laravel/profile_page.dart';
import 'package:flutter_laravel/pengiriman_page.dart';
import 'package:flutter_laravel/alamat_page.dart';
import 'package:flutter_laravel/histori_pesanan.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.id, this.name, this.email, this.type});

  final int? id;
  final String? name;
  final String? email;
  final String? type;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? id;
  bool isAdmin = false;
  bool isCustomer = false;
  String? name;
  String? email;

  @override
  void initState() {
    super.initState();
    fetchData();
    getTypeValue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Belanja Hemat dan Mudah",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),

      // navigation drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              accountName: Text(
                name ?? "Belum Login",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                email ?? "Belum Login",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              currentAccountPicture: Image(
                image: AssetImage("assets/img/Logo_small.png"),
              ),
            ),
            if (!isAdmin && !isCustomer) ...[
              ListTile(
                leading: Icon(Icons.home),
                title: Text("Login"),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => PageLogin()));
                },
              ),
            ] else ...[
              if (isAdmin) ...[
                ListTile(
                  leading: Icon(Icons.train),
                  title: Text("Tambah Barang"),
                  onTap: () {
                    Navigator.of(
                      context,
                    ).push<bool>(MaterialPageRoute(builder: (context) => const AddProduk())).then((value) {
                      if (value == true) {
                        setState(() {}); // Trigger rebuild to fetch data again
                      }
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text("Pesanan"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PesananAdminPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_shipping),
                  title: Text("Pengiriman"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PengirimanPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text("Histori"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoriPesananPage()),
                    );
                  },
                ),
              ],
              if (isCustomer) ...[
                ListTile(
                  leading: Icon(Icons.shopping_cart),
                  title: Text("Keranjang"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const KeranjangPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text("Pesanan"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PesananPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_shipping),
                  title: Text("Pengiriman"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PengirimanPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text("Histori"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoriPesananPage()),
                    );
                  },
                ),
              ],
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text("Alamat"),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AlamatPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text("Profil"),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text("Logout"),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => PageLogin()));
                },
              ),
            ],
            
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: FutureBuilder<List<ProdukResponModel>>(
            future: fetchData(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var rawGambar = snapshot.data![index].fotoProduk;
                    var gambar = (rawGambar != null && rawGambar != 'null' && rawGambar.isNotEmpty)
                        ? rawGambar
                        : 'download.jpg';
                    return Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                      width: double.infinity,
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 20, 4),
                                width: 150,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Color(0xffdbd8dd),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      '$gambarUrl/produk/$gambar?${DateTime.now().millisecondsSinceEpoch}'
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Text(
                                'Stok: ${snapshot.data![index].stok}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          Container(
                            width: 100,
                            height: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.fromLTRB(2, 0, 0, 10),
                                    child: Text(
                                      snapshot.data![index].namaProduk
                                          .toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 0, 0, 4),
                                  child: Text(
                                    "Harga: Rp ${snapshot.data![index].hargaProduk}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isAdmin == true) ...[
                                  Container(
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            var idBarang = snapshot
                                                .data![index]
                                                .idProduk
                                                .toString();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => EditForm(idBarang: idBarang),
                                              ),
                                            );
                                          },
                                          icon: Icon(Icons.edit, color: Colors.amber),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            var idBarang = snapshot
                                                .data![index]
                                                .idProduk
                                                .toString();
                                            Navigator.of(context)
                                                .push<bool>(MaterialPageRoute(
                                              builder: (context) => HapusProduk(idBarang: idBarang),
                                            )).then((value) {
                                              if (value == true) {
                                                setState(() {}); // refresh list
                                              }
                                            });
                                          },
                                          icon: Icon(Icons.delete, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            var idBarang = snapshot.data![index].idProduk.toString();
                                            addToCart(idBarang);
                                          },
                                          icon: const Icon(Icons.add_box, color: Colors.green),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                             final imgUrl = '$gambarUrl/produk/${(snapshot.data![index].fotoProduk != null && snapshot.data![index].fotoProduk != 'null' && snapshot.data![index].fotoProduk!.isNotEmpty) ? snapshot.data![index].fotoProduk : 'download.jpg'}?${DateTime.now().millisecondsSinceEpoch}';
                                             final desc = snapshot.data![index].deskripsiProduk ?? '';
                                             showDialog(
                                               context: context,
                                               builder: (_) => Dialog(
                                                 insetPadding: EdgeInsets.all(16),
                                                 child: Column(
                                                   mainAxisSize: MainAxisSize.min,
                                                   children: [
                                                     ConstrainedBox(
                                                       constraints: BoxConstraints(
                                                         maxWidth: MediaQuery.of(context).size.width * 0.9,
                                                         maxHeight: MediaQuery.of(context).size.width * 0.9,
                                                       ),
                                                       child: InteractiveViewer(
                                                         child: Image.network(imgUrl, fit: BoxFit.contain),
                                                       ),
                                                     ),
                                                     Padding(
                                                       padding: const EdgeInsets.all(12.0),
                                                       child: Column(
                                                         crossAxisAlignment: CrossAxisAlignment.start,
                                                         children: [
                                                           Text(snapshot.data![index].namaProduk ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                                                           const SizedBox(height: 4),
                                                           Text('Berat: ${snapshot.data![index].berat ?? '-'} g'),
                                                           Text('Stok: ${snapshot.data![index].stok ?? '-'}'),
                                                           Text('Harga: Rp ${snapshot.data![index].hargaProduk ?? '-'}'),
                                                           const Divider(),
                                                           Text(desc),
                                                         ],
                                                       ),
                                                     )
                                                   ],
                                                 ),
                                               ),
                                             );
                                           },
                                           icon: const Icon(Icons.linked_camera, color: Colors.blue),
                                         ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              // Return a loading indicator while waiting for data
              return Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Future<List<ProdukResponModel>> fetchData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/getProduk'),
      headers: {
        'Content-Type':
            'application/json; charset=UTF-8; Connection: KeepAlive',
      },
    );

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      //final Map<String, dynamic> result =
      jsonDecode(response.body);
      //return ProdukResponModel.fromJson(result);
      List data = jsonDecode(response.body);
      List<ProdukResponModel> produkList = data
          .map((e) => ProdukResponModel.fromJson(e))
          .toList();
      return produkList;
    } else {
      throw Exception('Failed to load Produk');
    }
  }

  getTypeValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? stringValue = prefs.getString('type');
    String? nama = prefs.getString('name');
    String? email1 = prefs.getString('email');
    setState(() {
      fetchData();
      if (stringValue == "admin") {
        isAdmin = true;
        isCustomer = false;
      } else if (stringValue == "customer") {
        isAdmin = false;
        isCustomer = true;
      } else {
        // guest
        isAdmin = false;
        isCustomer = false;
      }
      name = nama;
      email = email1;
    });
  }

  logOut() async {
    // untuk logout
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  goEdit(idBarang) {
    //untuk edit
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => EditForm(idBarang: idBarang)),
    // );
  }

  Future<void> addToCart(String idProduk) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/keranjang/storeApi'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: {
          'id_produk': idProduk,
          'quantity': '1',
          if (userId != null) 'id_user': userId.toString(),
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menambah ke keranjang')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menambah ke keranjang')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> delete(String idBarang) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/deleteApi/$idBarang'),
      );
      if (response.statusCode == 200) {
        if (!mounted) return; // Cek apakah context masih aktif
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Data Berhasil dihapus'),
              content: const Text("Data Berhasil dihapus"),
              actions: <Widget>[
                // ignore: deprecated_member_use
                ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    setState(() {
                      fetchData();
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text("Histori"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoriPesananPage()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to delete data');
      }
    } catch (error) {
      print(error);
    }
  }
}