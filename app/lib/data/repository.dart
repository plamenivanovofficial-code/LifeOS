import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../models/memory.dart';
import 'local_db.dart';
import 'sync_service.dart';

class Repository {
  final SyncService sync;
  final _uuid = const Uuid();
  Repository(this.sync);

  /// Записва мисъл локално веднага, после се опитва да синхронизира.
  Future<void> capture(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    final now = DateTime.now().toUtc();
    final m = Memory()
      ..uid = _uuid.v4()
      ..text = text
      ..kind = 'note'
      ..createdAt = now
      ..updatedAt = now
      ..deleted = false
      ..rev = 0
      ..synced = false;
    await LocalDb.isar.writeTxn(() => LocalDb.isar.memorys.put(m));
    sync.syncNow(); // fire-and-forget
  }

  /// Меко изтриване — нищо не се губи, само се скрива.
  Future<void> remove(Memory m) async {
    m.deleted = true;
    m.updatedAt = DateTime.now().toUtc();
    m.synced = false;
    await LocalDb.isar.writeTxn(() => LocalDb.isar.memorys.put(m));
    sync.syncNow();
  }

  /// Поток с видимите записи, най-новите отгоре. UI чете оттук.
  Stream<List<Memory>> watch() {
    final q = LocalDb.isar.memorys
        .filter()
        .deletedEqualTo(false)
        .sortByCreatedAtDesc();
    return q.watch(fireImmediately: true);
  }
}
