import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String? id;
  final String postId;
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
    id: map['id']?.toString(),
    postId: map['postId'].toString(),
    user: map['user'] as String,
    text: map['text'] as String,
    date: map['date'] as String,
  );

  factory CommentModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CommentModel(
      id: doc.id,
      postId:
          data['postId'] as String? ?? doc.reference.parent.parent?.id ?? '',
      user: data['user'] as String? ?? '',
      text: data['text'] as String? ?? '',
      date: data['date'] as String? ?? '',
    );
  }
}
