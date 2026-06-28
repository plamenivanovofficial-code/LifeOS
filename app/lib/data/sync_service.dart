import 'package:isar/isar.dart';

import '../models/memory.dart';
import 'api.dart';
import 'local_db.dart';

/// Offline-first sync. Никога не блокира UI.
/// 1) качва локалните непратени промени (push)
/// 2) сваля чуждите промени (pull) и ги слива по last-write-wins
class SyncService {
  final _api = Api();
  bool _running = false;

  Future<void> syncNow() async {
    if (_running) return;
    _running = true;
    try {
      await _push();
      await _pull();
    } catch (_) {
      // офлайн или сървърът го няма — нищо. Опитваме пак по-късно.
    } finally {
      _running = false;
    }
  }

  Future<void> _push() async {
    final isar = LocalDb.isar;
    final pending = await isar.memorys.filter().syncedEqualTo(false).findAll();
    if (pending.isEmpty) return;
    final ok = await _api.push(pending);
    if (ok) {
      await isar.writeTxn(() async {
        for (final m in pending) {
          m.synced = true;
          await isar.memorys.put(m);
        }
      });
    }
  }

  Future<void> _pull() async {
    final isar = LocalDb.isar;
    final since = await LocalDb.localCursor();
    final (rows, _) = await _api.pull(since);
    if (rows.isEmpty) return;

    await isar.writeTxn(() async {
      for (final r in rows) {
        final uid = r['id'] as String;
        final incomingUpdated = DateTime.parse(r['updated_at'] as String).toUtc();
        final existing =
            await isar.memorys.filter().uidEqualTo(uid).findFirst();

        // last-write-wins: пазим по-новото
        if (existing != null &&
            existing.updatedAt.toUtc().isAfter(incomingUpdated)) {
          continue;
        }
        final m = existing ?? Memory()
          ..uid = uid;
        m.text = r['text'] as String;
        m.kind = (r['kind'] as String?) ?? 'note';
        m.createdAt = DateTime.parse(r['created_at'] as String).toUtc();
        m.updatedAt = incomingUpdated;
        m.deleted = (r['deleted'] as bool?) ?? false;
        m.rev = (r['rev'] as int?) ?? 0;
        m.synced = true; // дошло е от сървъра
        await isar.memorys.put(m);
      }
    });
  }
}
