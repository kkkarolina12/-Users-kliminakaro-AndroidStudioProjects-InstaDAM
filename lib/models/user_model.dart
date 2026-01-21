lass UserModel {
  final int? id;
  final String username;
  final String password;

  UserModel({this.id, required this.username, required this.password});

  Map<String, Object?> toMap() => {
        'id': id,
        'username': username,
        'password': password,
      };

  factory UserModel.fromMap(Map<String, Object?> map) => UserModel(
        id: map['id'] as int?,
        username: map['username'] as String,
        password: map['password'] as String,
      );
}
