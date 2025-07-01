class ProdukResponModel {
  int? idProduk;
  String? namaProduk;
  int? idKategori;
  String? berat;
  int? stok;
  int? hargaProduk;
  String? deskripsiProduk;
  String? fotoProduk;
  String? createdAt;
  String? updatedAt;
  String? namaKategori;

  ProdukResponModel({
    this.idProduk,
    this.namaProduk,
    this.idKategori,
    this.berat,
    this.stok,
    this.hargaProduk,
    this.deskripsiProduk,
    this.fotoProduk,
    this.createdAt,
    this.updatedAt,
    this.namaKategori,
  });

  ProdukResponModel.fromJson(Map<String, dynamic> json) {
    idProduk = json['id_produk'];
    namaProduk = json['nama_produk'];
    idKategori = json['id_kategori'];
    berat = json['berat'];
    stok = json['stok'];
    hargaProduk = json['harga_produk'];
    deskripsiProduk = json['deskripsi_produk'];
    fotoProduk = json['foto_produk'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    namaKategori = json['nama_kategori'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id_produk'] = idProduk;
    data['nama_produk'] = namaProduk;
    data['id_kategori'] = idKategori;
    data['berat'] = berat;
    data['stok'] = stok;
    data['harga_produk'] = hargaProduk;
    data['deskripsi_produk'] = deskripsiProduk;
    data['foto_produk'] = fotoProduk;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['nama_kategori'] = namaKategori;
    return data;
  }
}
