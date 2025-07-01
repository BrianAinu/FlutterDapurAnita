// Model keranjang (cart item)
class KeranjangItem {
  int? id; // id keranjang
  int? userId;
  int? productId;
  int? qty;
  int? hargaProduk;
  String? namaProduk;
  String? fotoProduk;
  String? createdAt;
  String? updatedAt;

  KeranjangItem({
    this.id,
    this.userId,
    this.productId,
    this.qty,
    this.hargaProduk,
    this.namaProduk,
    this.fotoProduk,
    this.createdAt,
    this.updatedAt,
  });

  KeranjangItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? json['id_keranjang'];
    userId = json['user_id'] ?? json['id_user'];
    productId = json['product_id'] ?? json['id_produk'];
    qty = json['qty'] ?? json['quantity'];
    hargaProduk = json['harga_produk'] ?? json['hargaProduk'];
    namaProduk = json['nama_produk'] ?? json['namaProduk'];
    fotoProduk = json['foto_produk'] ?? json['fotoProduk'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['product_id'] = productId;
    data['qty'] = qty;
    data['harga_produk'] = hargaProduk;
    data['nama_produk'] = namaProduk;
    data['foto_produk'] = fotoProduk;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
