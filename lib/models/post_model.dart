class PostModel {
  final int? id;
  final String user;
  final String imagePath; // puede ser "placeholder"
  final String description;
  final String date; // ISO string
  final int likes; // total likes

  PostModel({
    this.id,
    required this.user,
    required this.imagePath,
    required this.description,
    required this.date,
    required this.likes,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'user': user,
        'imagePath': imagePath,
        'description': description,
        'date': date,
        'likes': likes,
      };

  factory PostModel.fromMap(Map<String, Object?> map) => PostModel(
        id: map['id'] as int?,
        user: map['user'] as String,
        imagePath: map['imagePath'] as String,
        description: map['description'] as String,
        date: map['date'] as String,
        likes: (map['likes'] as int?) ?? 0,
      );
}
