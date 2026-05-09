class UserModel {
  final Object? id;
  final String username;
  final String password;

  UserModel({this.id, required this.username, required this.password});

  Map<String, dynamic> toMap() {
    return {'id': id, 'username': username, 'password': password};
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      password: map['password'],
    );
  }
}

class UserProfile {
  final String username;
  final String name;
  final String bio;
  final String photoUrl;

  const UserProfile({
    required this.username,
    required this.name,
    required this.bio,
    required this.photoUrl,
  });
}
