class UserModel {
  final int? id;
  final String name;

  UserModel({
    this.id,
    required this.name,
  });

  // Konversi ke Map untuk simpan ke SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Konversi dari Map ke object UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
    );
  }
}
