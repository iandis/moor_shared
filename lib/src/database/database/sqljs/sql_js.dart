import 'dart:collection';

import 'package:isolated_worker/js_isolated_worker.dart';
import 'package:moor/moor.dart';

bool _areScriptsImported = false;
const List<String> _sqlJsWrapperFile = <String>[
  'sql-wasm.js',
  'sql-js-wrapper.js',
];

Future<SqlJsWrapper> initSqlJsWrapper() async {
  if (!_areScriptsImported) {
    final bool isLoaded = await JsIsolatedWorker().importScripts(_sqlJsWrapperFile);
    if (!isLoaded) {
      throw UnsupportedError('Web Worker not available on the browser');
    }
    _areScriptsImported = true;
  }
  await JsIsolatedWorker().run(
    functionName: 'initSqlJsWrapper',
    arguments: null,
  );
  return const SqlJsWrapper();
}

class SqlJsWrapper {
  const SqlJsWrapper();

  Future<void> createDb([Uint8List data]) async {
    await JsIsolatedWorker().run(
      functionName: 'sqlCreateDb',
      arguments: data,
    );
  }

  Future<void> run(String sql) async {
    await JsIsolatedWorker().run(
      functionName: 'sqlRun',
      arguments: <String, String>{
        'sql': sql,
      },
    );
  }

  Future<void> runWithArgs(String sql, List<dynamic> args) async {
    await JsIsolatedWorker().run(
      functionName: 'sqlRun',
      arguments: <String, Object>{
        'sql': sql,
        'args': args,
      },
    );
  }

  Future<SqlJsStatement> prepare(String sql) async {
    final int statementId = await JsIsolatedWorker().run(
      functionName: 'sqlSTMTPrepare',
      arguments: sql,
    ) as int;
    return SqlJsStatement(id: statementId);
  }

  Future<int> get lastModifiedRows async {
    return await JsIsolatedWorker().run(
      functionName: 'sqlGetRowsModified',
      arguments: null,
    ) as int;
  }

  Future<Uint8List> export() async {
    return await JsIsolatedWorker().run(
      functionName: 'sqlExport',
      arguments: null,
    ) as Uint8List;
  }

  Future<void> close() async {
    await JsIsolatedWorker().run(
      functionName: 'sqlClose',
      arguments: null,
    );
  }

  Future<int> get lastInsertId async {
    return await _selectSingleRowAndColumn('SELECT last_insert_rowid();') as int;
  }

  Future<dynamic> _selectSingleRowAndColumn(String sql) async {
    final List<dynamic> results = await JsIsolatedWorker().run(
      functionName: 'sqlExec',
      arguments: sql,
    ) as List<dynamic>;

    final LinkedHashMap<dynamic, dynamic> firstRow = results.first as LinkedHashMap<dynamic, dynamic>;
    final dynamic firstValue = (firstRow['values'] as List<dynamic>).first;
    return firstValue;
  }
}

class SqlJsStatement {
  const SqlJsStatement({
    @required this.id,
  }) : assert(id != null);

  final int id;

  Future<void> bind(List<dynamic> data) async {
    await JsIsolatedWorker().run(
      functionName: 'sqlSTMTBind',
      arguments: <String, dynamic>{
        'id': id,
        'data': data,
      },
    );
  }

  Future<bool> step() async {
    return await JsIsolatedWorker().run(
      functionName: 'sqlSTMTStep',
      arguments: id,
    ) as bool;
  }

  Future<List<dynamic>> getCurrentRow() async {
    return await JsIsolatedWorker().run(
      functionName: 'sqlSTMTGetCurrentRow',
      arguments: id,
    ) as List<dynamic>;
  }

  Future<List<String>> getColumnNames() async {
    return await JsIsolatedWorker().run(
      functionName: 'sqlSTMTGetColumnNames',
      arguments: id,
    ) as List<String>;
  }

  Future<void> free() async {
    await JsIsolatedWorker().run(
      functionName: 'sqlSTMTFree',
      arguments: id,
    );
  }
}
