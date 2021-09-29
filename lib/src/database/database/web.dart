import 'package:moor_shared/src/database/database/sqljs/js_db.dart';

import '../database.dart';

Database constructDb({bool logStatements = false}) {
  return Database(SqlJsDatabase(
    'todo_db',
    migrateFromLocalStorage: false,
  ));
}
