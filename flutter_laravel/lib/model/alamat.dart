class Alamat {
  final int id;
  final int idUser;
  String namaPenerima;
  String noTelp;
  int idProvinsi;
  String namaProv;
  int idKota;
  String namaKota;
  String kodePos;
  String alamatLengkap;

  Alamat({
    required this.id,
    required this.idUser,
    required this.namaPenerima,
    required this.noTelp,
    required this.idProvinsi,
    required this.namaProv,
    required this.idKota,
    required this.namaKota,
    required this.kodePos,
    required this.alamatLengkap,
  });

  factory Alamat.fromJson(Map<String, dynamic> json) {
    return Alamat(
      id: json['id_alamat'] ?? json['id'] ?? 0,
      idUser: json['id_user'],
      namaPenerima: json['nama_penerima'],
      noTelp: json['no_telp'],
      idProvinsi: json['id_provinsi'],
      namaProv: json['nama_prov'],
      idKota: json['id_kota'],
      namaKota: json['nama_kota'],
      kodePos: json['kode_pos'],
      alamatLengkap: json['alamat_lengkap'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_alamat': id,
      'id_user': idUser,
      'nama_penerima': namaPenerima,
      'no_telp': noTelp,
      'id_provinsi': idProvinsi,
      'nama_prov': namaProv,
      'id_kota': idKota,
      'nama_kota': namaKota,
      'kode_pos': kodePos,
      'alamat_lengkap': alamatLengkap,
    };
  }
}
