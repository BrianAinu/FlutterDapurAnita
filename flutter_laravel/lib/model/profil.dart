class Profil {
  final int id;
  String? name;
  String? email;
  String? hp;
  String? type;
  String? photo;

  Profil({
    required this.id,
    this.name,
    this.email,
    this.hp,
    this.type,
    this.photo,
  });

  factory Profil.fromJson(Map<String, dynamic> json) {
    return Profil(
      id: json['id'] ?? 0,
      name: json['name'],
      email: json['email'],
      hp: json['hp'],
      type: json['type'],
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'hp': hp,
      'type': type,
      'photo': photo,
    };
  }
}