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
  return SqlJsWrapper();
}

class SqlJsWrapper {
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
