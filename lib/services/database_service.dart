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

  Future<void> _createTables(Database d) async {
    await d.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS posts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user TEXT,
        imagePath TEXT,
        description TEXT,
        date TEXT,
        likes INTEGER DEFAULT 0
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS likes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER,
        user TEXT
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER,
        user TEXT,
        text TEXT,
        date TEXT
      )
    ''');
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'instadam.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (d, v) async {
        await _createTables(d);
      },
      onUpgrade: (d, oldVersion, newVersion) async {
        // Migración: recrear tablas preservando datos existentes
        await d.execute('CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, password TEXT)');
        await d.execute('CREATE TABLE IF NOT EXISTS posts(id INTEGER PRIMARY KEY AUTOINCREMENT, user TEXT, imagePath TEXT, description TEXT, date TEXT, likes INTEGER DEFAULT 0)');
        await d.execute('CREATE TABLE IF NOT EXISTS likes(id INTEGER PRIMARY KEY AUTOINCREMENT, postId INTEGER, user TEXT)');
        await d.execute('CREATE TABLE IF NOT EXISTS comments(id INTEGER PRIMARY KEY AUTOINCREMENT, postId INTEGER, user TEXT, text TEXT, date TEXT)');
      },
    );
  }

  // USERS
  Future<bool> usernameExists(String username) async {
    final d = await db;
    final rows = await d.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

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

  Future<int> updatePost(int id, String newDescription) async {
    final d = await db;
    return d.update(
      'posts',
      {'description': newDescription},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePost(int id) async {
    final d = await db;
    await d.transaction((txn) async {
      // Borrar likes asociados
      await txn.delete('likes', where: 'postId = ?', whereArgs: [id]);
      // Borrar comentarios asociados
      await txn.delete('comments', where: 'postId = ?', whereArgs: [id]);
      // Borrar el post
      await txn.delete('posts', where: 'id = ?', whereArgs: [id]);
    });
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

  Future<int> deleteComment(int id) async {
    final d = await db;
    return d.delete('comments', where: 'id = ?', whereArgs: [id]);
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
