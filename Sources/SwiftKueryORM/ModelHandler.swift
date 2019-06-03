//
//  ModelHandler.swift
//  SwiftKueryORM
//
//  Created by Matthew Kilner on 03/06/2019.
//

import Foundation
import Dispatch
import SwiftKuery
import KituraContracts

public class ModelHandler {

    // Table management functions

    @discardableResult
    static func createTableSync<M: Model>(for type: M.Type, using db: Database? = nil) throws -> Bool {
        var result: Bool?
        var error: RequestError?
        let semaphore = DispatchSemaphore(value: 0)
        createTable(for: type, using: db) { res, err in
            result = res
            error = err
            semaphore.signal()
        }
        semaphore.wait()

        if let errorUnwrapped = error {
            throw errorUnwrapped
        }
        guard let resultUnwrapped = result else {
            throw RequestError(.ormInternalError, reason: "Database table creation function did not return expected result (both result and error were nil)")
        }

        return resultUnwrapped
    }

    static func createTable<M: Model>(for type: M.Type, using db: Database? = nil, _ onCompletion: @escaping (Bool?, RequestError?) -> Void) {
        var table: Table
        do {
            table = try getTable(for: M.self)
        } catch let error {
            return onCompletion(nil, convertError(error))
        }
        executeTask(using: db) { connection, error in
            guard let connection = connection else {
                guard let error = error else {
                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
                }
                return onCompletion(nil, convertError(error))
            }
            table.create(connection: connection) { result in
                guard result.success else {
                    guard let error = result.asError else {
                        onCompletion(nil, convertError(QueryError.databaseError("Query failed to execute but error was nil")))
                        return
                    }
                    onCompletion(nil, convertError(error))
                    return
                }
                onCompletion(true, nil)
            }
        }
    }

    @discardableResult
    static func dropTableSync<M: Model>(for type: M.Type, using db: Database? = nil) throws -> Bool {
        var result: Bool?
        var error: RequestError?
        let semaphore = DispatchSemaphore(value: 0)
        dropTable(for: type, using: db) { res, err in
            result = res
            error = err
            semaphore.signal()
        }
        semaphore.wait()

        if let errorUnwrapped = error {
            throw errorUnwrapped
        }
        guard let resultUnwrapped = result else {
            throw RequestError(.ormInternalError, reason: "Database table creation function did not return expected result (both result and error were nil)")
        }

        return resultUnwrapped
    }

    static func dropTable<M: Model>(for type: M.Type, using db : Database? = nil, _ onCompletion: @escaping (Bool?, RequestError?) -> Void) {
        var table: Table
        do {
            table = try getTable(for: M.self)
        } catch let error {
            return onCompletion(nil, convertError(error))
        }
        executeTask(using: db) { connection, error in
            guard let connection = connection else {
                guard let error = error else {
                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
                }
                return onCompletion(nil, convertError(error))
            }
            connection.execute(query: table.drop()) { result in
                guard result.success else {
                    guard let error = result.asError else {
                        onCompletion(nil, convertError(QueryError.databaseError("Query failed to execute but error was nil")))
                        return
                    }
                    onCompletion(nil, convertError(error))
                    return
                }
                onCompletion(true, nil)
            }
        }
    }

    // Model interaction functions

    static func save<M: Model>(instance: M, of type: M.Type, using db: Database? = nil, _ onCompletion: @escaping (M?, RequestError?) -> Void) {
        var table: Table
        var values: [String : Any]
        do {
            table = try getTable(for: type)
            values = try DatabaseEncoder().encode(instance, dateEncodingStrategy: M.dateEncodingFormat)
        } catch let error {
            onCompletion(nil, convertError(error))
            return
        }

        let columns = table.columns.filter({values[$0.name] != nil})
        let parameters: [Any?] = columns.map({values[$0.name]!})
        let parameterPlaceHolders: [Parameter] = parameters.map {_ in return Parameter()}
        let query = Insert(into: table, columns: columns, values: parameterPlaceHolders)
        executeQuery(for: instance, query: query, parameters: parameters, using: db, onCompletion)
    }

    static func update<M: Model>(instance: M, of type: M.Type, using db: Database? = nil, _ onCompletion: @escaping (M?, RequestError?) -> Void) {
        var table: Table
        var values: [String: Any]
        do {
            table = try getTable(for: type)
            values = try DatabaseEncoder().encode(instance, dateEncodingStrategy: M.dateEncodingFormat)
        } catch let error {
            onCompletion(nil, convertError(error))
            return
        }

        let columns = table.columns.filter({$0.autoIncrement != true})
        var parameters: [Any?] = columns.map({values[$0.name]})
        let parameterPlaceHolders: [(Column, Any)] = columns.map({($0, Parameter())})
        guard let idColumn = table.columns.first(where: {$0.name == "modelID"}) else {
            onCompletion(nil, RequestError(rawValue: 708, reason: "Could not find id column"))
            return
        }

        let query = Update(table, set: parameterPlaceHolders).where(idColumn == Parameter())
        parameters.append(instance.modelID)
        executeQuery(for: instance, query: query, parameters: parameters, using: db, onCompletion)
    }

    static func delete<M: Model>(instance: M, of type: M.Type, using db: Database? = nil, _ onCompletion: @escaping (RequestError?) -> Void) {
        var table: Table
        do {
            table = try getTable(for: type)
        } catch let error {
            onCompletion(convertError(error))
            return
        }

        guard let idColumn = table.columns.first(where: {$0.name == "modelID"}) else {
            onCompletion(RequestError(.ormNotFound, reason: "Could not find id column"))
            return
        }

        let query = Delete(from: table).where(idColumn == Parameter())
        let parameters: [Any?] = [instance.modelID]
        executeQuery(query: query, parameters: parameters, using: db, onCompletion)
    }

    static func deleteAll<M: Model>(of type: M.Type, using db: Database? = nil, _ onCompletion: @escaping (RequestError?) -> Void) {
        var table: Table
        do {
            table = try getTable(for: type)
        } catch let error {
            onCompletion(convertError(error))
            return
        }

        let query = Delete(from: table)
        executeQuery(query: query, using: db, onCompletion)
    }

    static func deleteAll<Q: QueryParams, M: Model>(of type: M.Type, using db: Database? = nil, matching queryParams: Q?, _ onCompletion: @escaping (RequestError?) -> Void) {
        var table: Table
        do {
            table = try getTable(for: type)
        } catch let error {
            onCompletion(convertError(error))
            return
        }

        var query: Delete = Delete(from: table)
        var parameters: [Any?]? = nil
        if let queryParams = queryParams {
            do {
                let values: [String: Any] = try QueryEncoder().encode(queryParams)
                if values.count < 1 {
                    onCompletion(RequestError(.ormQueryError, reason: "Could not extract values for Query Parameters"))
                }
                let filterInfo = try getFilter(values: values, table: table)
                if let filter = filterInfo.filter,
                    let filterParameters = filterInfo.parameters {
                    parameters = filterParameters
                    query = query.where(filter)
                } else {
                    onCompletion(RequestError(.ormQueryError, reason: "Value for Query Parameters found but could not be added to a database delete query"))
                    return
                }
            } catch let error {
                onCompletion(convertError(error))
                return
            }
        }
        executeQuery(query: query, parameters: parameters, using: db, onCompletion)
    }

    static func find<M: Model>(instanceOf type: M.Type, withID id: Int64, using db: Database? = nil, _ onCompletion: @escaping (M?, RequestError?) -> Void) {
        var table: Table
        do {
            table = try getTable(for: type)
        } catch let error {
            onCompletion(nil, convertError(error))
            return
        }

        guard let idColumn = table.columns.first(where: {$0.name == "modelID"}) else {
            onCompletion(nil, RequestError(.ormInvalidTableDefinition, reason: "Could not find id column"))
            return
        }

        let query = Select(from: table).where(idColumn == Parameter())
        let parameters: [Any?] = [id]
        executeQuery(query: query, parameters: parameters, using: db, onCompletion)
    }

    static func findAll<M: Model>(of type: M.Type, using db: Database? = nil, _ onCompletion: @escaping ([M]?, RequestError?) -> Void) {
        var table: Table
        do {
            table = try getTable(for: type)
        } catch let error {
            onCompletion(nil, convertError(error))
            return
        }

        let query = Select(from: table)
        executeQuery(query: query, using: db, onCompletion)
    }

    static func findAll<Q: QueryParams, M: Model>(of type: M.Type, using db: Database? = nil, matching queryParams: Q? = nil, _ onCompletion: @escaping ([M]?, RequestError?) -> Void) {
        var table: Table
        do {
            table = try getTable(for: type)
        } catch let error {
            onCompletion(nil, convertError(error))
            return
        }

        var query: Select = Select(from: table)
        var parameters: [Any?]? = nil
        if let queryParams = queryParams {
            do {
                (query, parameters) = try getSelectQueryWithFilters(query: query, queryParams: queryParams, table: table)
            } catch let error {
                onCompletion(nil, convertError(error))
                return
            }
        }
        executeQuery(query: query, parameters: parameters, using: db, onCompletion)
    }

    // Query execution functions

    private static func executeQuery<M: Model>(for instance: M, query: Query, parameters: [Any?], using db: Database? = nil, _ onCompletion: @escaping (M?, RequestError?) -> Void ) {
        var dictionaryTitleToValue = [String: Any?]()
        executeTask(using: db) { connection, error in
            guard let connection = connection else {
                guard let error = error else {
                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
                }
                return onCompletion(nil, convertError(error))
            }
            connection.execute(query: query, parameters: parameters) { result in
                guard result.success else {
                    guard let error = result.asError else {
                        onCompletion(nil, convertError(QueryError.databaseError("Query failed to execute but error was nil")))
                        return
                    }
                    onCompletion(nil, convertError(error))
                    return
                }
                if let _ = query as? Insert {
                    result.asRows() { rows, error in
                        guard let rows = rows, rows.count > 0 else {
                            onCompletion(nil, RequestError(.ormNotFound, reason: "Could not retrieve value for Query: \(String(describing: query))"))
                            return
                        }

                        dictionaryTitleToValue = rows[0]

                        guard let value = dictionaryTitleToValue["modelID"] else {
                            onCompletion(nil, RequestError(.ormNotFound, reason: "Could not find return id"))
                            return
                        }

                        guard let unwrappedValue: Any = value else {
                            onCompletion(nil, RequestError(.ormNotFound, reason: "Return id is nil"))
                            return
                        }

                        do {
                            let newValue = try Int64(value: String(describing: unwrappedValue))
                            var newSelf = instance
                            newSelf.modelID = newValue

                            return onCompletion(newSelf, nil)
                        } catch {
                            return onCompletion(nil, RequestError(.ormInternalError, reason: "Unable to convert identifier"))
                        }
                    }
                } else {
                    return onCompletion(instance, nil)
                }
            }
        }
    }

    static func executeQuery(query: Query, parameters: [Any?]? = nil, using db: Database? = nil, _ onCompletion: @escaping (RequestError?) -> Void ) {
        executeTask(using: db) { connection, error in
            guard let connection = connection else {
                guard let error = error else {
                    return onCompletion(RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
                }
                return onCompletion(convertError(error))
            }
            let executeCompletion = { (result: QueryResult) in
                guard result.success else {
                    guard let error = result.asError else {
                        onCompletion(convertError(QueryError.databaseError("Query failed to execute but error was nil")))
                        return
                    }
                    onCompletion(convertError(error))
                    return
                }
                onCompletion(nil)
            }

            if let parameters = parameters {
                connection.execute(query: query, parameters: parameters, onCompletion: executeCompletion)
            } else {
                connection.execute(query: query, onCompletion: executeCompletion)
            }
        }
    }

    static func executeQuery<M: Model>(query: Query, parameters: [Any?], using db: Database? = nil, _ onCompletion: @escaping (M?, RequestError?) -> Void ) {
        executeTask(using: db) { connection, error in
            guard let connection = connection else {
                guard let error = error else {
                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
                }
                return onCompletion(nil, convertError(error))
            }
            connection.execute(query: query, parameters: parameters) { result in
                guard result.success else {
                    guard let error = result.asError else {
                        onCompletion(nil, convertError(QueryError.databaseError("Query failed to execute but error was nil")))
                        return
                    }
                    onCompletion(nil, convertError(error))
                    return
                }

                result.asRows() { rows, error in
                    guard let rows = rows, rows.count > 0 else {
                        onCompletion(nil, RequestError(.ormNotFound, reason: "Could not retrieve value for Query: \(String(describing: query))"))
                        return
                    }

                    let dictionaryTitleToValue: [String: Any?] = rows[0]

                    var decodedModel: M
                    do {
                        decodedModel = try DatabaseDecoder().decode(M.self, dictionaryTitleToValue, dateEncodingStrategy: M.dateEncodingFormat)
                    } catch {
                        onCompletion(nil, convertError(error))
                        return
                    }

                    onCompletion(decodedModel, nil)
                }
            }
        }
    }

    static func executeQuery<M: Model>(query: Query, parameters: [Any?]? = nil, using db: Database? = nil, _ onCompletion: @escaping ([M]?, RequestError?)-> Void ) {
        executeTask(using: db) { connection, error in
            guard let connection = connection else {
                guard let error = error else {
                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
                }
                return onCompletion(nil, convertError(error))
            }
            let executeCompletion = { (result: QueryResult) in
                guard result.success else {
                    guard let error = result.asError else {
                        onCompletion(nil, convertError(QueryError.databaseError("Query failed to execute but error was nil")))
                        return
                    }
                    onCompletion(nil, convertError(error))
                    return
                }

                if case QueryResult.successNoData = result {
                    onCompletion([], nil)
                    return
                }

                result.asRows() { rows, error in
                    guard let rows = rows else {
                        onCompletion(nil, RequestError(.ormNotFound, reason: "Could not retrieve values from table: \(String(describing: getTableName(for: M.self))))"))
                        return
                    }

                    var dictionariesTitleToValue = [[String: Any?]]()

                    for row in rows {
                        dictionariesTitleToValue.append(row)
                    }

                    var list = [M]()
                    for dictionary in dictionariesTitleToValue {
                        var decodedModel: M
                        do {
                            decodedModel = try DatabaseDecoder().decode(M.self, dictionary, dateEncodingStrategy: M.dateEncodingFormat)
                        } catch {
                            onCompletion(nil, convertError(error))
                            return
                        }

                        list.append(decodedModel)
                    }

                    onCompletion(list, nil)
                }
            }

            if let parameters = parameters {
                connection.execute(query: query, parameters: parameters, onCompletion: executeCompletion)
            } else {
                connection.execute(query: query, onCompletion: executeCompletion)
            }
        }
    }

    // Utility functions

    private static func convertError(_ error: Error) -> RequestError {
        switch error {
        case let requestError as RequestError:
            return requestError
        case let queryError as QueryError:
            return RequestError(.ormQueryError, reason: String(describing: queryError))
        case let decodingError as DecodingError:
            return RequestError(.ormCodableDecodingError, reason: String(describing: decodingError))
        default:
            return RequestError(.ormInternalError, reason: String(describing: error))
        }
    }

    private static func executeTask(using db: Database? = nil, task: @escaping ((Connection?, QueryError?) -> ())) {
        guard let database = db ?? Database.default else {

            return task(nil, QueryError.databaseError("ORM database not initialised"))
        }
        database.executeTask(task: task)
    }

    static func getTableName<M: Model>(for type: M.Type) -> String {
        var tableName = String(describing: type)
        if tableName.last != "s" {
            tableName += "s"
        }
        return tableName
    }

    static func getTable<M: Model>(for type: M.Type) throws -> Table {
        return try Database.tableInfo.getTable(getTableName(for: M.self), for: M.self, with: M.dateEncodingFormat)
    }

    // Filtering functions

    private static func getFilter(values: [String: Any], table: Table) throws -> (filter: Filter?, parameters: [Any?]?) {
        var columnsToValues: [(column: Column, opr: Operator, value: String)] = []

        for column in table.columns {
            if let value = values[column.name] {
                var stringValue = String(describing: value)
                var opr: Operator = .equal
                if let operation = value as? KituraContracts.Operation {
                    opr = operation.getOperator()
                    stringValue = operation.getStringValue()
                } else if var array = value as? Array<Any> {
                    opr = .or
                    stringValue = String(describing: array.removeFirst())
                    for val in array {
                        stringValue += ",\(val)"
                    }
                }
                columnsToValues.append((column, opr, stringValue))
            }
        }

        if columnsToValues.count < 1 {
            return (nil, nil)
        }

        let firstTuple = columnsToValues.removeFirst()
        let resultTuple = try extractFilter(firstTuple.column, firstTuple.opr, firstTuple.value)
        var filter = resultTuple.filter
        var parameters: [Any?] = resultTuple.parameters

        for (column, opr, value) in columnsToValues {
            let resultTuple = try extractFilter(column, opr, value)
            parameters.append(contentsOf: resultTuple.parameters)
            filter = filter && resultTuple.filter
        }

        return (filter, parameters)
    }

    private static func extractFilter(_ column: Column, _ opr: Operator, _ value: String) throws -> (filter: Filter, parameters: [Any?]) {
        let filter: Filter
        var parameters: [Any?] = [value]
        switch opr {
        case .equal:
            filter = (column == Parameter())
        case .greaterThan:
            filter = (column > Parameter())
        case .greaterThanOrEqual:
            filter = (column >= Parameter())
        case .lowerThan:
            filter = (column < Parameter())
        case .lowerThanOrEqual:
            filter = (column <= Parameter())
        case .inclusiveRange:
            let array = value.split(separator: ",")
            if array.count == 2 {
                filter = (column >= Parameter()) && (column <= Parameter())
                parameters = array.map { String($0) }
            } else {
                throw RequestError(.ormQueryError, reason: "Could not extract values for Query Parameters")
            }
        case .exclusiveRange:
            let array = value.split(separator: ",")
            if array.count == 2 {
                filter = (column > Parameter()) && (column < Parameter())
                parameters = array.map { String($0) }
            } else {
                throw RequestError(.ormQueryError, reason: "Could not extract values for Query Parameters")
            }
        case .or:
            let array = value.split(separator: ",")
            if array.count > 1 {
                var newFilter: Filter = (column == Parameter())
                for _ in array {
                    newFilter = newFilter || (column == Parameter())
                }
                filter = newFilter
                parameters = array.map { String($0) }
            } else {
                filter = (column == Parameter())
            }
        }

        return (filter, parameters)
    }

    private static func getSelectQueryWithFilters<Q: QueryParams>(query: Select, queryParams: Q, table: Table) throws -> (query: Select, parameters: [Any?]?) {
        let values: [String: Any] = try QueryEncoder().encode(queryParams)
        if values.count < 1 {
            throw RequestError(.ormQueryError, reason: "Could not extract values for Query Parameters")
        }
        let filterInfo = try getFilter(values: values, table: table)
        let order: [OrderBy] = getOrderBy(values: values, table: table)
        let pagination = getPagination(values: values)

        var resultQuery = query
        var parameters: [Any?]? = nil
        var success = false
        if let filter = filterInfo.filter,
            let filterParameters = filterInfo.parameters {
            parameters = filterParameters
            resultQuery = resultQuery.where(filter)
            success = true
        }

        if order.count > 0 {
            resultQuery = resultQuery.order(by: order)
            success = true
        }

        if let pagination = pagination {
            resultQuery = resultQuery.limit(to: pagination.limit).offset(pagination.offset)
            success = true
        }

        if !success {
            throw RequestError(.ormQueryError, reason: "QueryParameters found but failed construct database query")
        }
        return (resultQuery, parameters)
    }

    private static func getPagination(values: [String: Any]) -> (limit: Int, offset: Int)? {
        var result: (limit: Int, offset: Int)? = nil
        for (_, value) in values {
            if let pagValue = value as? Pagination {
                let pagValues = pagValue.getValues()
                result = (limit: pagValues.size, offset: pagValues.start)
            }
        }

        return result
    }

    private static func getOrderBy(values: [String: Any], table: Table) -> [OrderBy] {
        var orderByArray: [OrderBy] = []
        for (_, value) in values {
            if let orderValue = value as? Ordering {
                let columnDictionary = table.columns.reduce(into: [String: Column]()) { dict, value in
                    dict[value.name] = value
                }
                let orders = orderValue.getValues()
                for order in orders where columnDictionary[order.value] != nil {
                    let column = columnDictionary[order.value]!
                    if case .asc(_) = order {
                        orderByArray.append(.ASC(column))
                    } else {
                        orderByArray.append(.DESC(column))
                    }
                }
            }
        }

        return orderByArray
    }
}
