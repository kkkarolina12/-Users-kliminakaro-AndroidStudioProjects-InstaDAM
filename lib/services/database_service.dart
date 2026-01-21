import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'instadam.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT
          )
        ''');

        await d.execute('''
          CREATE TABLE posts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user TEXT,
            imagePath TEXT,
            description TEXT,
            date TEXT,
            likes INTEGER DEFAULT 0
          )
        ''');

        await d.execute('''
          CREATE TABLE likes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            postId INTEGER,
            user TEXT
          )
        ''');

        await d.execute('''
          CREATE TABLE comments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            postId INTEGER,
            user TEXT,
            text TEXT,
            date TEXT
          )
        ''');
      },
    );
  }

  // USERS
  Future<int> registerUser(UserModel user) async {
    final d = await db;
    return d.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<UserModel?> login(String username, String password) async {
    final d = await db;
    final rows = await d.query('users',
        where: 'username = ? AND password = ?', whereArgs: [username, password], limit: 1);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  // POSTS
  Future<int> createPost(PostModel post) async {
    final d = await db;
    return d.insert('posts', post.toMap());
  }

  Future<List<PostModel>> getAllPosts() async {
    final d = await db;
    final rows = await d.query('posts', orderBy: 'id DESC');
    return rows.map((e) => PostModel.fromMap(e)).toList();
  }

  Future<List<PostModel>> getPostsByUser(String username) async {
    final d = await db;
    final rows = await d.query('posts', where: 'user = ?', whereArgs: [username], orderBy: 'id DESC');
    return rows.map((e) => PostModel.fromMap(e)).toList();
  }

  // LIKES
  Future<bool> isLikedByUser({required int postId, required String username}) async {
    final d = await db;
    final rows = await d.query('likes',
        where: 'postId = ? AND user = ?', whereArgs: [postId, username], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> toggleLike({required int postId, required String username}) async {
    final d = await db;

    final liked = await isLikedByUser(postId: postId, username: username);

    if (liked) {
      await d.delete('likes', where: 'postId = ? AND user = ?', whereArgs: [postId, username]);
      await d.rawUpdate('UPDATE posts SET likes = likes - 1 WHERE id = ? AND likes > 0', [postId]);
    } else {
      await d.insert('likes', {'postId': postId, 'user': username});
      await d.rawUpdate('UPDATE posts SET likes = likes + 1 WHERE id = ?', [postId]);
    }
  }

  // COMMENTS
  Future<int> addComment(CommentModel c) async {
    final d = await db;
    return d.insert('comments', c.toMap());
  }

  Future<List<CommentModel>> getCommentsByPost(int postId) async {
    final d = await db;
    final rows = await d.query('comments', where: 'postId = ?', whereArgs: [postId], orderBy: 'id ASC');
    return rows.map((e) => CommentModel.fromMap(e)).toList();
  }

  Future<int> getCommentsCount(int postId) async {
    final d = await db;
    final res = Sqflite.firstIntValue(
      await d.rawQuery('SELECT COUNT(*) FROM comments WHERE postId = ?', [postId]),
    );
    return res ?? 0;
  }
}
