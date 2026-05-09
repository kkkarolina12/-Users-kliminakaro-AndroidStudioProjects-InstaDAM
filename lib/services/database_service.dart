import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  static const defaultBio =
      'Estudiante de DAM. Amante de la fotografia y el desarrollo movil.';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  String _userId(String username) => username.trim().toLowerCase();

  bool _isRemoteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Future<String> _uploadFile({
    required String path,
    required String storagePath,
  }) async {
    if (path.isEmpty || path == 'placeholder' || _isRemoteUrl(path)) {
      return path;
    }

    final file = File(path);
    if (!file.existsSync()) return path;

    final ref = _storage.ref(storagePath);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _deleteStorageUrl(String value) async {
    if (!_isRemoteUrl(value)) return;
    try {
      await _storage.refFromURL(value).delete();
    } catch (_) {
      // The Firestore document is the source of truth; missing Storage files
      // should not block deleting or updating data.
    }
  }

  // USERS
  Future<bool> usernameExists(String username) async {
    final doc = await _users.doc(_userId(username)).get();
    return doc.exists;
  }

  Future<String> registerUser(UserModel user) async {
    final userId = _userId(user.username);
    final ref = _users.doc(userId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        throw StateError('duplicate username');
      }

      transaction.set(ref, {
        'username': user.username.trim(),
        'password': user.password,
        'name': user.username.trim(),
        'bio': defaultBio,
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return userId;
  }

  Future<UserModel?> login(String username, String password) async {
    final doc = await _users.doc(_userId(username)).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || data['password'] != password) return null;

    return UserModel.fromMap({
      'id': doc.id,
      'username': (data['username'] as String?) ?? username,
      'password': data['password'] as String,
    });
  }

  Future<UserProfile> getUserProfile(String username) async {
    final doc = await _users.doc(_userId(username)).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      return UserProfile(
        username: username,
        name: username,
        bio: defaultBio,
        photoUrl: '',
      );
    }

    final savedUsername = (data['username'] as String?) ?? username;
    return UserProfile(
      username: savedUsername,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : savedUsername,
      bio: (data['bio'] as String?) ?? defaultBio,
      photoUrl: (data['photoUrl'] as String?) ?? '',
    );
  }

  Future<void> updateUserProfile({
    required String username,
    required String name,
    required String bio,
    String? photoPath,
  }) async {
    final userId = _userId(username);
    final ref = _users.doc(userId);
    final existing = await ref.get();
    final existingPhoto = existing.data()?['photoUrl'] as String? ?? '';

    var photoUrl = existingPhoto;
    if (photoPath != null && photoPath.isNotEmpty && photoPath != photoUrl) {
      photoUrl = await _uploadFile(
        path: photoPath,
        storagePath: 'users/$userId/profile.jpg',
      );
    }

    await ref.set({
      'username': username,
      'name': name.trim().isEmpty ? username : name.trim(),
      'bio': bio.trim(),
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // POSTS
  Future<String> createPost(PostModel post) async {
    final ref = _posts.doc();
    final imagePath = await _uploadFile(
      path: post.imagePath,
      storagePath: 'posts/${ref.id}/image.jpg',
    );

    await ref.set({
      'user': post.user,
      'imagePath': imagePath,
      'description': post.description,
      'date': post.date,
      'likes': post.likes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Future<void> updatePost(String id, String newDescription) async {
    await _posts.doc(id).update({
      'description': newDescription,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String id) async {
    final postRef = _posts.doc(id);
    final post = await postRef.get();
    final imagePath = post.data()?['imagePath'] as String? ?? '';

    await _deleteCollection(postRef.collection('likes'));
    await _deleteCollection(postRef.collection('comments'));
    await postRef.delete();
    await _deleteStorageUrl(imagePath);
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(450).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<List<PostModel>> getAllPosts() async {
    final snapshot = await _posts.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  Future<List<PostModel>> getPostsByUser(String username) async {
    final snapshot = await _posts.where('user', isEqualTo: username).get();
    final posts = snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList();
    posts.sort((a, b) => b.date.compareTo(a.date));
    return posts;
  }

  // LIKES
  Future<bool> isLikedByUser({
    required String postId,
    required String username,
  }) async {
    final doc = await _posts
        .doc(postId)
        .collection('likes')
        .doc(_userId(username))
        .get();
    return doc.exists;
  }

  Future<void> toggleLike({
    required String postId,
    required String username,
  }) async {
    final postRef = _posts.doc(postId);
    final likeRef = postRef.collection('likes').doc(_userId(username));

    await _firestore.runTransaction((transaction) async {
      final like = await transaction.get(likeRef);

      if (like.exists) {
        transaction.delete(likeRef);
        transaction.update(postRef, {'likes': FieldValue.increment(-1)});
      } else {
        transaction.set(likeRef, {
          'user': username,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {'likes': FieldValue.increment(1)});
      }
    });
  }

  // COMMENTS
  Future<String> addComment(CommentModel c) async {
    final ref = _posts.doc(c.postId).collection('comments').doc();
    await ref.set({
      'postId': c.postId,
      'user': c.user,
      'text': c.text,
      'date': c.date,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteComment(String postId, String id) async {
    await _posts.doc(postId).collection('comments').doc(id).delete();
  }

  Future<List<CommentModel>> getCommentsByPost(String postId) async {
    final snapshot = await _posts
        .doc(postId)
        .collection('comments')
        .orderBy('date')
        .get();
    return snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
  }

  Future<int> getCommentsCount(String postId) async {
    final snapshot = await _posts.doc(postId).collection('comments').get();
    return snapshot.size;
  }
}
