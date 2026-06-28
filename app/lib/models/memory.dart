import 'package:isar/isar.dart';

part 'memory.g.dart'; // генерира се с: dart run build_runner build

@collection
class Memory {
  Id isarId = Isar.autoIncrement; // вътрешен ключ на Isar

  @Index(unique: true, replace: true)
  late String uid; // глобален UUID — общ със сървъра, основата на sync-а

  late String text;
  String kind = 'note';

  late DateTime createdAt; // кога се е случило
  late DateTime updatedAt; // последна промяна (last-write-wins)

  bool deleted = false; // меко изтриване — нищо не се губи
  int rev = 0;          // сървърен номер; 0 = още не е виждан от сървъра
  bool synced = false;  // false = чака качване (push)
}
