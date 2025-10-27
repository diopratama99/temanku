import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _db = AppDatabase();
  int? _currentUserId;
  Map<String, dynamic>? _currentUser;

  int? get currentUserId => _currentUserId;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<void> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    final id = sp.getInt('currentUserId');
    if (id != null) {
      await _loadUserById(id);
    }
  }

  Future<void> _loadUserById(int id) async {
    final rows = await _db.db.query(
      'users',
      where: 'id=?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      _currentUserId = id;
      _currentUser = rows.first;
    } else {
      await logout();
    }
  }

  String _hashPassword(String password) {
    // Simple SHA-256; not equivalent to werkzeug but fine for local-only
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Pastikan DB sudah terbuka
    await _db.init();
    final db = _db.db;
    try {
      final id = await db.insert('users', {
        'name': name,
        'email': email.trim().toLowerCase(),
        'password_hash': _hashPassword(password),
      });
      // Seed kategori default secara async agar UI tidak menunggu
      unawaited(_db.seedDefaultCategories(id));
      _currentUserId = id;
      await _loadUserById(id);
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('currentUserId', id);
      return null;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return 'Email sudah terdaftar';
      }
      return 'Gagal daftar: $e';
    } catch (e) {
      return 'Gagal daftar: $e';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    await _db.init();
    final db = _db.db;
    final rows = await db.query(
      'users',
      where: 'email=?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return 'Email atau password salah';
    final row = rows.first;
    final hashed = row['password_hash'] as String?;
    if (hashed == _hashPassword(password)) {
      _currentUserId = row['id'] as int;
      _currentUser = row;
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('currentUserId', _currentUserId!);
      return null;
    }
    return 'Email atau password salah';
  }

  Future<String?> loginWithGoogle() async {
    try {
      await _db.init();
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) return 'Login Google dibatalkan';

      final email = account.email.toLowerCase();
      final name = account.displayName ?? email.split('@').first;
      final picture = account.photoUrl;
      final googleId = account.id; // use as google_sub equivalent

      // Link or create
      final existingBySub = await _db.db.query(
        'users',
        where: 'google_sub=?',
        whereArgs: [googleId],
        limit: 1,
      );
      Map<String, dynamic>? userRow;
      if (existingBySub.isNotEmpty) {
        userRow = existingBySub.first;
      } else {
        final existingByEmail = await _db.db.query(
          'users',
          where: 'email=?',
          whereArgs: [email],
          limit: 1,
        );
        if (existingByEmail.isNotEmpty) {
          final id = existingByEmail.first['id'] as int;
          await _db.db.update(
            'users',
            {'google_sub': googleId, 'picture': picture},
            where: 'id=?',
            whereArgs: [id],
          );
          userRow = (await _db.db.query(
            'users',
            where: 'id=?',
            whereArgs: [id],
            limit: 1,
          )).first;
        } else {
          final id = await _db.db.insert('users', {
            'name': name,
            'email': email,
            'password_hash': _hashPassword(DateTime.now().toIso8601String()),
            'google_sub': googleId,
            'picture': picture,
          });
          await _db.seedDefaultCategories(id);
          userRow = (await _db.db.query(
            'users',
            where: 'id=?',
            whereArgs: [id],
            limit: 1,
          )).first;
        }
      }

      _currentUserId = userRow!['id'] as int;
      _currentUser = userRow;
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('currentUserId', _currentUserId!);
      return null;
    } catch (e) {
      return 'Gagal login Google: $e';
    }
  }

  Future<void> logout() async {
    _currentUserId = null;
    _currentUser = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove('currentUserId');
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUserId != null) {
      await _loadUserById(_currentUserId!);
    }
  }
}
