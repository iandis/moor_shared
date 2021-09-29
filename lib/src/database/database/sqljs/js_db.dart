import 'dart:async';
import 'dart:typed_data';

import 'package:moor/backends.dart';
import 'package:moor/moor_web.dart';

import 'sql_js.dart';

class SqlJsDatabase extends DelegatedDatabase {
  SqlJsDatabase(
    String name, {
    bool migrateFromLocalStorage = true,
  }) : super(_SqlJsDelegate(MoorWebStorage.indexedDb(
          name,
          migrateFromLocalStorage: migrateFromLocalStorage,
          inWebWorker: true,
        )));
}

class _SqlJsDelegate extends DatabaseDelegate {
  _SqlJsDelegate(this.storage);

  final MoorWebStorage storage;

  SqlJsWrapper _sqlJsWrapper;

  bool _isOpen = false;

  @override
  bool get isOpen => _isOpen;

  bool _inTransaction = false;
  @override
  set isInTransaction(bool value) {
    _inTransaction = value;

    if (!_inTransaction) {
      // transaction completed, save the database!
      _storeDb();
    }
  }

  @override
  Future<void> open(QueryExecutorUser db) async {
    _sqlJsWrapper = await initSqlJsWrapper();

    await storage.open();
    final Uint8List restored = await storage.restore();

    if (restored != null) {
      await storage.store(restored);
    }

    await _sqlJsWrapper.createDb(restored);
    _isOpen = true;
  }

  @override
  Future<void> runBatched(BatchedStatements statements) {
    // TODO: implement runBatched
    throw UnimplementedError();
  }

  @override
  Future<void> runCustom(String statement, List<Object> args) {
    return _sqlJsWrapper.runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object> args) async {
    await _sqlJsWrapper.runWithArgs(statement, args);
    final int insertId = await _sqlJsWrapper.lastInsertId;
    await _handlePotentialUpdate();
    return insertId;
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object> args) {
    // TODO: implement runSelect
    throw UnimplementedError();
  }

  @override
  Future<int> runUpdate(String statement, List<Object> args) async {
    await _sqlJsWrapper.runWithArgs(statement, args);
    return _handlePotentialUpdate();
  }

  /// Saves the database if the last statement changed rows. As a side-effect,
  /// saving the database resets the `last_insert_id` counter in sqlite.
  Future<int> _handlePotentialUpdate() async {
    final int modified = await _sqlJsWrapper.lastModifiedRows;
    if (modified > 0) {
      await _storeDb();
    }
    return modified;
  }

  Future<void> _storeDb() async {
    if (!isInTransaction) {
      await storage.store(await _sqlJsWrapper.export());
    }
  }

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  DbVersionDelegate get versionDelegate =>
      _versionDelegate ??= _WebVersionDelegate(this);
  DbVersionDelegate _versionDelegate;
}

class _WebVersionDelegate extends DynamicVersionDelegate {
  final _SqlJsDelegate delegate;

  _WebVersionDelegate(this.delegate);

  // Note: Earlier moor versions used to store the database version in a special
  // field in local storage (moor_db_version_<name>). Since 2.3, we instead use
  // the user_version pragma, but still need to keep backwards compatibility.

  @override
  Future<int> get schemaVersion async {
    return 1;
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    // TODO: implement setSchemaVersion
  }
}