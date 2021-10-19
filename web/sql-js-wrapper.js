/**
 * @typedef SqlJsQueryExecResult
 * @type {object}
 * @property {Array<string>} columns
 * @property {Array<any>} values
 */

/**
 * @typedef SqlJsRunParams
 * @type {object}
 * @property {string} sql
 * @property {any[]} args
 */

/**
 * @typedef SqlJsSTMTBindParams
 * @type {object}
 * @property {number} id
 * @property {any} data
 */

class SqlJsWorkerError {
    /**
     * 
     * @param {string} message 
     */
    constructor(message) {
        this.message = message;
        this.name = 'SqlJsWorkerError';
    }
}

var db, SQL;

async function initSqlJsWrapper(_) {
    if (typeof SQL !== 'undefined' || typeof db !== 'undefined') {
        return;
    }
    SQL = await initSqlJs();
}

/**
 * @param {Uint8Array} dbData 
 */
function sqlCreateDb(dbData) {
    db = new SQL.Database(dbData);
}

/**
 * Execute an SQL query, ignoring the rows it returns
 * @param {SqlJsRunParams} params
 */
function sqlRun(params) {
    if (typeof SQL === 'undefined' || typeof db === 'undefined') {
        throw SqlJsWorkerError('Database has not been initialized!');
    }
    const { sql, args } = params;
    db.run(sql, args);
}

/**
 * Execute an SQL query, and returns the result.
 * 
 * This is a wrapper against Database.prepare, Statement.bind, Statement.step, Statement.get, and Statement.free.
 * 
 * The result is an array of result elements. 
 * There are as many result elements as the number of statements in your sql string (statements are separated by a semicolon)
 * @param {string} sql 
 * @returns {Array<SqlJsQueryExecResult>} result of sqlExec
 */
function sqlExec(sql) {
    if (typeof SQL === 'undefined' || typeof db === 'undefined') {
        throw SqlJsWorkerError('Database has not been initialized!');
    }
    /** @type {Array<SqlJsQueryExecResult>} */
    const result = db.exec(sql);
    return result;
}

/**
 * 
 * @returns {Uint8Array} 
 */
function sqlExport(_) {
    if (typeof SQL === 'undefined' || typeof db === 'undefined') {
        throw SqlJsWorkerError('Database has not been initialized!');
    }

    return db.export();
}

/**
 * 
 * @returns {number}
 */
function sqlGetRowsModified(_) {
    if (typeof SQL === 'undefined' || typeof db === 'undefined') {
        throw SqlJsWorkerError('Database has not been initialized!');
    }

    return db.getRowsModified();
}

function sqlClose(_) {
    if (typeof SQL === 'undefined' || typeof db === 'undefined') {
        throw SqlJsWorkerError('Database has not been initialized!');
    }

    db.close();
    SQL = undefined;
    db = undefined;
}

// STATEMENTS

/**
 * 
 * @param {string} sql 
 * @returns {number}
 */
function sqlSTMTPrepare(sql) {
    if (typeof SQL === 'undefined' || typeof db === 'undefined') {
        throw SqlJsWorkerError('Database has not been initialized!');
    }

    const statement = db.prepare(sql);
    _resetIdIfReachedMax();
    const statementId = _statementIds++;
    _statements[statementId] = statement;
    return statementId;
}

/**
 * 
 * @param {SqlJsSTMTBindParams} args 
 */
function sqlSTMTBind(args) {
    const storedStatement = _statements[args.id];
    if (storedStatement) {
        storedStatement.bind(args.data);
    }
    throw SqlJsWorkerError('Statement object undefined!');
}

/**
 * 
 * @param {number} statementId
 * @returns {boolean}
 */
function sqlSTMTStep(statementId) {
    const storedStatement = _statements[statementId];
    if (storedStatement) {
        return storedStatement.step();
    }
    throw SqlJsWorkerError('Statement object undefined!');
}

/**
 * 
 * @param {number} statementId 
 * @returns {any[]}
 */

function sqlSTMTGetCurrentRow(statementId) {
    const storedStatement = _statements[statementId];
    if (storedStatement) {
        return storedStatement.get();
    }
    throw SqlJsWorkerError('Statement object undefined!');
}

/**
 * 
 * @param {number} statementId 
 * @returns {string[]}
 */
function sqlSTMTGetColumnNames(statementId) {
    const storedStatement = _statements[statementId];
    if (storedStatement) {
        return storedStatement.getColumnNames();
    }
    throw SqlJsWorkerError('Statement object undefined!');
}

/**
 * 
 * @param {number} statementId 
 */

function sqlSTMTFree(statementId) {
    const storedStatement = _statements[statementId];
    if (storedStatement) {
        storedStatement.free();
        delete storedStatement[statementId];
    }
    throw SqlJsWorkerError('Statement object undefined!');
}

let _statementIds = 0;

const _resetIdIfReachedMax = () => {
    if (_statementIds >= 1e9) {
        _statementIds = 0;
    }
}

const _statements = {};