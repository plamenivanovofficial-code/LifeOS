import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/memory.dart';

class LocalDb {
  static late final Isar isar;

  static Future<void> open() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([MemorySchema], directory: dir.path);
  }

  // Курсорът за sync пазим просто в самата база чрез отделен запис не ни трябва —
  // вместо това ползваме max(rev) от локалните записи като долна граница на pull.
  static Future<int> localCursor() async {
    final newest = await isar.memorys.where().sortByRevDesc().findFirst();
    return newest?.rev ?? 0;
  }
}
