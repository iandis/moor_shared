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

