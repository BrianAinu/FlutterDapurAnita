// Model pesanan (order)
class Pesanan {
  int? idPesanan;
  int? idProduk;
  int? idUser;
  int? quantity;
  int? hargaTotalBayar;
  int? hargaProduk;
  String? buktiBayar;
  String? namaProduk;
  String? fotoProduk;
  String? name;
  String? tipePembayaran;
  String? noResi;
  String? alamatLengkap;
  String? namaKota;
  String? namaProv;
  String? noTelp;
  String? status;
  String? createdAt;
  String? updatedAt;

  Pesanan({
    this.idPesanan,
    this.idProduk,
    this.idUser,
    this.quantity,
    this.hargaTotalBayar,
    this.hargaProduk,
    this.buktiBayar,
    this.namaProduk,
    this.fotoProduk,
    this.name,
    this.tipePembayaran,
    this.noResi,
    this.alamatLengkap,
    this.namaKota,
    this.namaProv,
    this.noTelp,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  Pesanan.fromJson(Map<String, dynamic> json) {
    idPesanan = json['id_pesanan'] ?? json['idPesanan'];
    idProduk = json['id_produk'] ?? json['idProduk'];
    idUser = json['id_user'] ?? json['idUser'];
    quantity = json['quantity'] ?? json['qty'];
    hargaTotalBayar = json['harga_total_bayar'] ?? json['hargaTotalBayar'];
     hargaProduk = json['harga_produk'];
    buktiBayar = json['bukti_bayar'];
    namaProduk = json['nama_produk'];
    fotoProduk = json['foto_produk'];
    name = json['name'] ?? json['nama_user'];
    tipePembayaran = json['tipe_pembayaran'] ?? json['tipePembayaran'];
    status = json['status']?.toString();
     noResi = json['no_resi']?.toString();
    alamatLengkap = json['alamat_lengkap'];
     namaKota = json['nama_kota'];
     namaProv = json['nama_prov'];
     noTelp = json['no_telp'];
     createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id_pesanan'] = idPesanan;
    data['id_produk'] = idProduk;
    data['id_user'] = idUser;
    data['quantity'] = quantity;
    data['harga_total_bayar'] = hargaTotalBayar;
    if(hargaProduk!=null) data['harga_produk']=hargaProduk;
    data['bukti_bayar'] = buktiBayar;
    data['nama_produk'] = namaProduk;
    data['foto_produk'] = fotoProduk;
    data['name'] = name;
    data['tipe_pembayaran'] = tipePembayaran;
    data['status'] = status;
     data['no_resi'] = noResi;
     data['alamat_lengkap'] = alamatLengkap;
     data['nama_kota'] = namaKota;
     data['nama_prov'] = namaProv;
     data['no_telp'] = noTelp;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
