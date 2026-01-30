import '../models/app_notification.dart';
import 'database_helper.dart';

class NotificationDataService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<AppNotification>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'notifications',
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => AppNotification.fromMap(m)).toList();
  }

  Future<int> getUnreadCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE isRead = 0',
    );
    return result.first['count'] as int;
  }

  Future<String> add(AppNotification notification) async {
    final db = await _db.database;
    final id = await db.insert('notifications', notification.toMap());
    return id.toString();
  }

  Future<void> markAsRead(String id) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllAsRead() async {
    final db = await _db.database;
    await db.update('notifications', {'isRead': 1});
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('notifications');
  }
}
