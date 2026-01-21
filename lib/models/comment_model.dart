class CommentModel {
  final int? id;
  final int postId;
  final String user;
  final String text;
  final String date;

  CommentModel({
    this.id,
    required this.postId,
    required this.user,
    required this.text,
    required this.date,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'postId': postId,
        'user': user,
        'text': text,
        'date': date,
      };

  factory CommentModel.fromMap(Map<String, Object?> map) => CommentModel(
        id: map['id'] as int?,
        postId: map['postId'] as int,
        user: map['user'] as String,
        text: map['text'] as String,
        date: map['date'] as String,
      );
}
