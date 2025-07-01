class Resi {
  final int? idResi;
  final int idPesanan;
  final String noResi;

  Resi({this.idResi, required this.idPesanan, required this.noResi});

  factory Resi.fromJson(Map<String, dynamic> json) {
    return Resi(
      idResi: json['id_resi'] ?? json['id'] as int?,
      idPesanan: int.parse(json['id_pesanan'].toString()),
      noResi: json['no_resi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_resi': idResi,
        'id_pesanan': idPesanan,
        'no_resi': noResi,
      };
}
