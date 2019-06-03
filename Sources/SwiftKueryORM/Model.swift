/**
 Copyright IBM Corporation 2018, 2019

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import SwiftKuery
import KituraContracts
import Foundation
import Dispatch

/// The DateEncodingFormat enumeration defines the supported formats for persisiting properties of type `Date`.
public enum DateEncodingFormat {
    /// time - Corresponds to the `time` column type
    case time
    /// date - Corresponds to the `date` column type
    case date
    /// timestamp - Corresponds to the `timestamp` column type.
    case timestamp
    /// double - This is the default encoding type and corresponds to Swifts encoding of `Date`.
    case double
}

/// Protocol Model conforming to Codable defining the available operations
public protocol Model: Codable {

    /// Holds the id of the model
    var modelID: Int64? { get set }

    /// Defines the format in which `Date` properties of the `Model` will be written to the Database. Defaults to .double
    static var dateEncodingFormat: DateEncodingFormat { get }
}

public extension Model {

    static var dateEncodingFormat: DateEncodingFormat { return .double }

//    private static func executeTask(using db: Database? = nil, task: @escaping ((Connection?, QueryError?) -> ())) {
//        guard let database = db ?? Database.default else {
//
//            return task(nil, QueryError.databaseError("ORM database not initialised"))
//        }
//        database.executeTask(task: task)
//    }

//    @discardableResult
//    static func createTableSync(using db: Database? = nil) throws -> Bool {
//        var result: Bool?
//        var error: RequestError?
//        let semaphore = DispatchSemaphore(value: 0)
//        createTable(using: db) { res, err in
//            result = res
//            error = err
//            semaphore.signal()
//        }
//        semaphore.wait()
//
//        if let errorUnwrapped = error {
//            throw errorUnwrapped
//        }
//        guard let resultUnwrapped = result else {
//            throw RequestError(.ormInternalError, reason: "Database table creation function did not return expected result (both result and error were nil)")
//        }
//
//        return resultUnwrapped
//    }

//    static func createTable(using db: Database? = nil, _ onCompletion: @escaping (Bool?, RequestError?) -> Void) {
//        var table: Table
//        do {
//            table = try Self.getTable()
//        } catch let error {
//            return onCompletion(nil, Self.convertError(error))
//        }
//        Self.executeTask(using: db) { connection, error in
//            guard let connection = connection else {
//                guard let error = error else {
//                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
//                }
//                return onCompletion(nil, Self.convertError(error))
//            }
//            table.create(connection: connection) { result in
//                guard result.success else {
//                    guard let error = result.asError else {
//                        onCompletion(nil, Self.convertError(QueryError.databaseError("Query failed to execute but error was nil")))
//                        return
//                    }
//                    onCompletion(nil, Self.convertError(error))
//                    return
//                }
//                onCompletion(true, nil)
//            }
//        }
//    }

//    @discardableResult
//    static func dropTableSync(using db: Database? = nil) throws -> Bool {
//        var result: Bool?
//        var error: RequestError?
//        let semaphore = DispatchSemaphore(value: 0)
//        dropTable(using: db) { res, err in
//            result = res
//            error = err
//            semaphore.signal()
//        }
//        semaphore.wait()
//
//        if let errorUnwrapped = error {
//            throw errorUnwrapped
//        }
//        guard let resultUnwrapped = result else {
//            throw RequestError(.ormInternalError, reason: "Database table creation function did not return expected result (both result and error were nil)")
//        }
//
//        return resultUnwrapped
//    }
//
//    static func dropTable(using db : Database? = nil, _ onCompletion: @escaping (Bool?, RequestError?) -> Void) {
//        var table: Table
//        do {
//            table = try Self.getTable()
//        } catch let error {
//            return onCompletion(nil, Self.convertError(error))
//        }
//        Self.executeTask(using: db) { connection, error in
//            guard let connection = connection else {
//                guard let error = error else {
//                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
//                }
//                return onCompletion(nil, Self.convertError(error))
//            }
//            connection.execute(query: table.drop()) { result in
//                guard result.success else {
//                    guard let error = result.asError else {
//                        onCompletion(nil, Self.convertError(QueryError.databaseError("Query failed to execute but error was nil")))
//                        return
//                    }
//                    onCompletion(nil, Self.convertError(error))
//                    return
//                }
//                onCompletion(true, nil)
//            }
//        }
//    }

//    func save(using db: Database? = nil, _ onCompletion: @escaping (Self?, RequestError?) -> Void) {
//        var table: Table
//        var values: [String : Any]
//        do {
//            table = try Self.getTable()
//            values = try DatabaseEncoder().encode(self, dateEncodingStrategy: Self.dateEncodingFormat)
//        } catch let error {
//            onCompletion(nil, Self.convertError(error))
//            return
//        }
//
//        let columns = table.columns.filter({values[$0.name] != nil})
//        let parameters: [Any?] = columns.map({values[$0.name]!})
//        let parameterPlaceHolders: [Parameter] = parameters.map {_ in return Parameter()}
//        let query = Insert(into: table, columns: columns, values: parameterPlaceHolders)
//        self.executeQuery(query: query, parameters: parameters, using: db, onCompletion)
//    }
//
//    func save<I: Identifier>(using db: Database? = nil, _ onCompletion: @escaping (I?, Self?, RequestError?) -> Void) {
//        var table: Table
//        var values: [String : Any]
//        do {
//            table = try Self.getTable()
//            values = try DatabaseEncoder().encode(self, dateEncodingStrategy: Self.dateEncodingFormat)
//        } catch let error {
//            onCompletion(nil, nil, Self.convertError(error))
//            return
//        }
//
//        let columns = table.columns.filter({$0.autoIncrement != true && values[$0.name] != nil})
//        let parameters: [Any?] = columns.map({values[$0.name]!})
//        let parameterPlaceHolders: [Parameter] = parameters.map {_ in return Parameter()}
//        let query = Insert(into: table, columns: columns, values: parameterPlaceHolders, returnID: true)
//        self.executeQuery(query: query, parameters: parameters, using: db, onCompletion)
//    }

//    func update<I: Identifier>(id: I, using db: Database? = nil, _ onCompletion: @escaping (Self?, RequestError?) -> Void) {
//        var table: Table
//        var values: [String: Any]
//        do {
//            table = try Self.getTable()
//            values = try DatabaseEncoder().encode(self, dateEncodingStrategy: Self.dateEncodingFormat)
//        } catch let error {
//            onCompletion(nil, Self.convertError(error))
//            return
//        }
//
//        let columns = table.columns.filter({$0.autoIncrement != true})
//        var parameters: [Any?] = columns.map({values[$0.name]})
//        let parameterPlaceHolders: [(Column, Any)] = columns.map({($0, Parameter())})
//        guard let idColumn = table.columns.first(where: {$0.name == "ormID"}) else {
//            onCompletion(nil, RequestError(rawValue: 708, reason: "Could not find id column"))
//            return
//        }
//
//        let query = Update(table, set: parameterPlaceHolders).where(idColumn == Parameter())
//        parameters.append(id.value)
//        executeQuery(query: query, parameters: parameters, using: db, onCompletion)
//    }

//    static func delete(id: Identifier, using db: Database? = nil, _ onCompletion: @escaping (RequestError?) -> Void) {
//        var table: Table
//        do {
//            table = try Self.getTable()
//        } catch let error {
//            onCompletion(Self.convertError(error))
//            return
//        }
//
//        guard let idColumn = table.columns.first(where: {$0.name == "ormID"}) else {
//            onCompletion(RequestError(.ormNotFound, reason: "Could not find id column"))
//            return
//        }
//
//        let query = Delete(from: table).where(idColumn == Parameter())
//        let parameters: [Any?] = [id.value]
//        Self.executeQuery(query: query, parameters: parameters, using: db, onCompletion)
//    }

//    static func deleteAll(using db: Database? = nil, _ onCompletion: @escaping (RequestError?) -> Void) {
//        var table: Table
//        do {
//            table = try Self.getTable()
//        } catch let error {
//            onCompletion(Self.convertError(error))
//            return
//        }
//
//        let query = Delete(from: table)
//        self.executeQuery(query: query, using: db, onCompletion)
//    }

    /// Delete all the models matching the QueryParams
    /// - Parameter using: Optional Database to use
    /// - Returns: An optional RequestError
//    static func deleteAll<Q: QueryParams>(using db: Database? = nil, matching queryParams: Q?, _ onCompletion: @escaping (RequestError?) -> Void) {
//        var table: Table
//        do {
//            table = try Self.getTable()
//        } catch let error {
//            onCompletion(Self.convertError(error))
//            return
//        }
//
//        var query: Delete = Delete(from: table)
//        var parameters: [Any?]? = nil
//        if let queryParams = queryParams {
//            do {
//                let values: [String: Any] = try QueryEncoder().encode(queryParams)
//                if values.count < 1 {
//                    onCompletion(RequestError(.ormQueryError, reason: "Could not extract values for Query Parameters"))
//                }
//                let filterInfo = try Self.getFilter(values: values, table: table)
//                if let filter = filterInfo.filter,
//                    let filterParameters = filterInfo.parameters {
//                    parameters = filterParameters
//                    query = query.where(filter)
//                } else {
//                    onCompletion(RequestError(.ormQueryError, reason: "Value for Query Parameters found but could not be added to a database delete query"))
//                    return
//                }
//            } catch let error {
//                onCompletion(Self.convertError(error))
//                return
//            }
//        }
//        Self.executeQuery(query: query, parameters: parameters, using: db, onCompletion)
//    }

//    private func executeQuery(query: Query, parameters: [Any?], using db: Database? = nil, _ onCompletion: @escaping (Self?, RequestError?) -> Void ) {
//        var dictionaryTitleToValue = [String: Any?]()
//        Self.executeTask(using: db) { connection, error in
//            guard let connection = connection else {
//                guard let error = error else {
//                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
//                }
//                return onCompletion(nil, Self.convertError(error))
//            }
//            connection.execute(query: query, parameters: parameters) { result in
//                guard result.success else {
//                    guard let error = result.asError else {
//                        onCompletion(nil, Self.convertError(QueryError.databaseError("Query failed to execute but error was nil")))
//                        return
//                    }
//                    onCompletion(nil, Self.convertError(error))
//                    return
//                }
//                if let insertQuery = query as? Insert, insertQuery.returnID {
//                    result.asRows() { rows, error in
//                        guard let rows = rows, rows.count > 0 else {
//                            onCompletion(nil, RequestError(.ormNotFound, reason: "Could not retrieve value for Query: \(String(describing: query))"))
//                            return
//                        }
//
//                        dictionaryTitleToValue = rows[0]
//
//                        guard let value = dictionaryTitleToValue["ormID"] else {
//                            onCompletion(nil, RequestError(.ormNotFound, reason: "Could not find return id"))
//                            return
//                        }
//
//                        guard let unwrappedValue: Any = value else {
//                            onCompletion(nil, RequestError(.ormNotFound, reason: "Return id is nil"))
//                            return
//                        }
//
//                        do {
//                            let newValue = try Int(value: String(describing: unwrappedValue))
//                            let newSelf = self
//                            newSelf.setORMID(to: newValue)
//
//                            return onCompletion(newSelf, nil)
//                        } catch {
//                            return onCompletion(nil, RequestError(.ormInternalError, reason: "Unable to convert identifier"))
//                        }
//                    }
//                } else {
//                    return onCompletion(self, nil)
//                }
//            }
//        }
//    }

    /// Allows custom functions on a model to query the database directly.
    /// - Parameter query: The `Query` to execute
    /// - Parameter parameters: An optional array of parameters to pass to the query
    /// - Parameter using: Optional Database to use
    /// - Parameter onCompletion: The function to be called when the execution of the query has completed. The function will be passed a tuple of (Self?, RequestError?), of which one will be nil, depending on whether the query was successful.
//    static func executeQuery(query: Query, parameters: [Any?], using db: Database? = nil, _ onCompletion: @escaping (Self?, RequestError?) -> Void ) {
//        Self.executeTask(using: db) { connection, error in
//            guard let connection = connection else {
//                guard let error = error else {
//                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
//                }
//                return onCompletion(nil, Self.convertError(error))
//            }
//            connection.execute(query: query, parameters: parameters) { result in
//                guard result.success else {
//                    guard let error = result.asError else {
//                        onCompletion(nil, Self.convertError(QueryError.databaseError("Query failed to execute but error was nil")))
//                        return
//                    }
//                    onCompletion(nil, Self.convertError(error))
//                    return
//                }
//
//                result.asRows() { rows, error in
//                    guard let rows = rows, rows.count > 0 else {
//                        onCompletion(nil, RequestError(.ormNotFound, reason: "Could not retrieve value for Query: \(String(describing: query))"))
//                        return
//                    }
//
//                    let dictionaryTitleToValue: [String: Any?] = rows[0]
//
//                    var decodedModel: Self
//                    do {
//                        decodedModel = try DatabaseDecoder().decode(Self.self, dictionaryTitleToValue, dateEncodingStrategy: Self.dateEncodingFormat)
//                    } catch {
//                        onCompletion(nil, Self.convertError(error))
//                        return
//                    }
//
//                    onCompletion(decodedModel, nil)
//                }
//            }
//        }
//    }

    /// Allows custom functions on a model to query the database directly.
    /// - Parameter query: The `Query` to execute
    /// - Parameter parameters: An optional array of parameters to pass to the query
    /// - Parameter using: Optional Database to use
    /// - Parameter onCompletion: The function to be called when the execution of the query has completed. The function will be passed a tuple of ([Self]?, RequestError?), of which one will be nil, depending on whether the query was successful.
//    static func executeQuery(query: Query, parameters: [Any?]? = nil, using db: Database? = nil, _ onCompletion: @escaping ([Self]?, RequestError?)-> Void ) {
//        Self.executeTask(using: db) { connection, error in
//            guard let connection = connection else {
//                guard let error = error else {
//                    return onCompletion(nil, RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
//                }
//                return onCompletion(nil, Self.convertError(error))
//            }
//            let executeCompletion = { (result: QueryResult) in
//                guard result.success else {
//                    guard let error = result.asError else {
//                        onCompletion(nil, Self.convertError(QueryError.databaseError("Query failed to execute but error was nil")))
//                        return
//                    }
//                    onCompletion(nil, Self.convertError(error))
//                    return
//                }
//
//                if case QueryResult.successNoData = result {
//                    onCompletion([], nil)
//                    return
//                }
//
//                result.asRows() { rows, error in
//                    guard let rows = rows else {
//                        onCompletion(nil, RequestError(.ormNotFound, reason: "Could not retrieve values from table: \(String(describing: Self.tableName)))"))
//                        return
//                    }
//
//                    var dictionariesTitleToValue = [[String: Any?]]()
//
//                    for row in rows {
//                        dictionariesTitleToValue.append(row)
//                    }
//
//                    var list = [Self]()
//                    for dictionary in dictionariesTitleToValue {
//                        var decodedModel: Self
//                        do {
//                            decodedModel = try DatabaseDecoder().decode(Self.self, dictionary, dateEncodingStrategy: Self.dateEncodingFormat)
//                        } catch {
//                            onCompletion(nil, Self.convertError(error))
//                            return
//                        }
//
//                        list.append(decodedModel)
//                    }
//
//                    onCompletion(list, nil)
//                }
//            }
//
//            if let parameters = parameters {
//                connection.execute(query: query, parameters: parameters, onCompletion: executeCompletion)
//            } else {
//                connection.execute(query: query, onCompletion: executeCompletion)
//            }
//        }
//    }

    /// Allows custom functions on a model to query the database directly.
    /// - Parameter query: The `Query` to execute
    /// - Parameter parameters: An optional array of parameters to pass to the query
    /// - Parameter using: Optional Database to use
    /// - Parameter onCompletion: The function to be called when the execution of the query has completed. The function will be passed a RequestError? which may be nil, depending on whether the query was successful.
//    static func executeQuery(query: Query, parameters: [Any?]? = nil, using db: Database? = nil, _ onCompletion: @escaping (RequestError?) -> Void ) {
//        Self.executeTask(using: db) { connection, error in
//            guard let connection = connection else {
//                guard let error = error else {
//                    return onCompletion(RequestError(.ormInternalError, reason: "Unknow error when getting connection"))
//                }
//                return onCompletion(Self.convertError(error))
//            }
//            let executeCompletion = { (result: QueryResult) in
//                guard result.success else {
//                    guard let error = result.asError else {
//                        onCompletion(Self.convertError(QueryError.databaseError("Query failed to execute but error was nil")))
//                        return
//                    }
//                    onCompletion(Self.convertError(error))
//                    return
//                }
//                onCompletion(nil)
//            }
//
//            if let parameters = parameters {
//                connection.execute(query: query, parameters: parameters, onCompletion: executeCompletion)
//            } else {
//                connection.execute(query: query, onCompletion: executeCompletion)
//            }
//        }
//    }

//    static func getTable() throws -> Table {
//        return try Database.tableInfo.getTable(("ormID", Int64.self), Self.tableName, for: Self.self, with: Self.dateEncodingFormat)
//    }

    /**
     This functions accepts a Select query, an instance of QueryParams and the database table.
     It returns the updated Select query containing the filtering values extracted from the QueryParameters and the parameters to inject in the SQL Query (this is to prevent SQL Injection)
     */
//    private static func getSelectQueryWithFilters<Q: QueryParams>(query: Select, queryParams: Q, table: Table) throws -> (query: Select, parameters: [Any?]?) {
//        let values: [String: Any] = try QueryEncoder().encode(queryParams)
//        if values.count < 1 {
//            throw RequestError(.ormQueryError, reason: "Could not extract values for Query Parameters")
//        }
//        let filterInfo = try Self.getFilter(values: values, table: table)
//        let order: [OrderBy] = Self.getOrderBy(values: values, table: table)
//        let pagination = Self.getPagination(values: values)
//
//        var resultQuery = query
//        var parameters: [Any?]? = nil
//        var success = false
//        if let filter = filterInfo.filter,
//            let filterParameters = filterInfo.parameters {
//            parameters = filterParameters
//            resultQuery = resultQuery.where(filter)
//            success = true
//        }
//
//        if order.count > 0 {
//            resultQuery = resultQuery.order(by: order)
//            success = true
//        }
//
//        if let pagination = pagination {
//            resultQuery = resultQuery.limit(to: pagination.limit).offset(pagination.offset)
//            success = true
//        }
//
//        if !success {
//            throw RequestError(.ormQueryError, reason: "QueryParameters found but failed construct database query")
//        }
//        return (resultQuery, parameters)
//    }

    /// This function converts the Query Parameter into a Filter used in SwiftKuery
    /// Parameters:
    /// - A generic QueryParams instance
    /// - A Table instance
    /// Steps:
    /// 1 - Convert the values in the QueryParams to a dictionary of String to String
    /// 2 - Construct an array of tuples (Column, Operator, Value)
    /// 3 - Verify that we have at least one tuple, else return nil
    /// 4 - Iterate through the tuples
    /// 5 - Remove the first tuple and create a filter with the getOperation() function
    /// 6 - If the array still as tuples, iterate through them and append a new filter (column == value) with an AND operator
    /// 7 - Finally, return the Filter

//    private static func getFilter(values: [String: Any], table: Table) throws -> (filter: Filter?, parameters: [Any?]?) {
//        var columnsToValues: [(column: Column, opr: Operator, value: String)] = []
//
//        for column in table.columns {
//            if let value = values[column.name] {
//                var stringValue = String(describing: value)
//                var opr: Operator = .equal
//                if let operation = value as? KituraContracts.Operation {
//                    opr = operation.getOperator()
//                    stringValue = operation.getStringValue()
//                } else if var array = value as? Array<Any> {
//                    opr = .or
//                    stringValue = String(describing: array.removeFirst())
//                    for val in array {
//                        stringValue += ",\(val)"
//                    }
//                }
//                columnsToValues.append((column, opr, stringValue))
//            }
//        }
//
//        if columnsToValues.count < 1 {
//            return (nil, nil)
//        }
//
//        let firstTuple = columnsToValues.removeFirst()
//        let resultTuple = try extractFilter(firstTuple.column, firstTuple.opr, firstTuple.value)
//        var filter = resultTuple.filter
//        var parameters: [Any?] = resultTuple.parameters
//
//        for (column, opr, value) in columnsToValues {
//            let resultTuple = try extractFilter(column, opr, value)
//            parameters.append(contentsOf: resultTuple.parameters)
//            filter = filter && resultTuple.filter
//        }
//
//        return (filter, parameters)
//    }

    /**
     This function creates the appropriate Filter from a Column , an Operator and a String value
     */

//    private static func extractFilter(_ column: Column, _ opr: Operator, _ value: String) throws -> (filter: Filter, parameters: [Any?]) {
//        let filter: Filter
//        var parameters: [Any?] = [value]
//        switch opr {
//        case .equal:
//            filter = (column == Parameter())
//        case .greaterThan:
//            filter = (column > Parameter())
//        case .greaterThanOrEqual:
//            filter = (column >= Parameter())
//        case .lowerThan:
//            filter = (column < Parameter())
//        case .lowerThanOrEqual:
//            filter = (column <= Parameter())
//        case .inclusiveRange:
//            let array = value.split(separator: ",")
//            if array.count == 2 {
//                filter = (column >= Parameter()) && (column <= Parameter())
//                parameters = array.map { String($0) }
//            } else {
//                throw RequestError(.ormQueryError, reason: "Could not extract values for Query Parameters")
//            }
//        case .exclusiveRange:
//            let array = value.split(separator: ",")
//            if array.count == 2 {
//                filter = (column > Parameter()) && (column < Parameter())
//                parameters = array.map { String($0) }
//            } else {
//                throw RequestError(.ormQueryError, reason: "Could not extract values for Query Parameters")
//            }
//        case .or:
//            let array = value.split(separator: ",")
//            if array.count > 1 {
//                var newFilter: Filter = (column == Parameter())
//                for _ in array {
//                    newFilter = newFilter || (column == Parameter())
//                }
//                filter = newFilter
//                parameters = array.map { String($0) }
//            } else {
//                filter = (column == Parameter())
//            }
//        }
//
//        return (filter, parameters)
//    }

    /**
     This function extracts the pagination values from the QueryParameters values
     */
//    private static func getPagination(values: [String: Any]) -> (limit: Int, offset: Int)? {
//        var result: (limit: Int, offset: Int)? = nil
//        for (_, value) in values {
//            if let pagValue = value as? Pagination {
//                let pagValues = pagValue.getValues()
//                result = (limit: pagValues.size, offset: pagValues.start)
//            }
//        }
//
//        return result
//    }

    /**
     This function constructs an array of OrderBy from the QueryParameters values
     */
//    private static func getOrderBy(values: [String: Any], table: Table) -> [OrderBy] {
//        var orderByArray: [OrderBy] = []
//        for (_, value) in values {
//            if let orderValue = value as? Ordering {
//                let columnDictionary = table.columns.reduce(into: [String: Column]()) { dict, value in
//                    dict[value.name] = value
//                }
//                let orders = orderValue.getValues()
//                for order in orders where columnDictionary[order.value] != nil {
//                    let column = columnDictionary[order.value]!
//                    if case .asc(_) = order {
//                        orderByArray.append(.ASC(column))
//                    } else {
//                        orderByArray.append(.DESC(column))
//                    }
//                }
//            }
//        }
//
//        return orderByArray
//    }

//    private static func convertError(_ error: Error) -> RequestError {
//        switch error {
//        case let requestError as RequestError:
//            return requestError
//        case let queryError as QueryError:
//            return RequestError(.ormQueryError, reason: String(describing: queryError))
//        case let decodingError as DecodingError:
//            return RequestError(.ormCodableDecodingError, reason: String(describing: decodingError))
//        default:
//            return RequestError(.ormInternalError, reason: String(describing: error))
//        }
//    }

    /// Find a model with an id
    /// - Parameter using: Optional Database to use
    /// - Returns: A tuple (Model, RequestError)
//    static func find<I: Identifier>(id: I, using db: Database? = nil, _ onCompletion: @escaping (Self?, RequestError?) -> Void) {
//        var table: Table
//        do {
//            table = try Self.getTable()
//        } catch let error {
//            onCompletion(nil, Self.convertError(error))
//            return
//        }
//
//        guard let idColumn = table.columns.first(where: {$0.name == "ormID"}) else {
//            onCompletion(nil, RequestError(.ormInvalidTableDefinition, reason: "Could not find id column"))
//            return
//        }
//
//        let query = Select(from: table).where(idColumn == Parameter())
//        let parameters: [Any?] = [id.value]
//        Self.executeQuery(query: query, parameters: parameters, using: db, onCompletion)
//    }


    ///
//    static func findAll(using db: Database? = nil, _ onCompletion: @escaping ([Self]?, RequestError?) -> Void) {
//        var table: Table
//        do {
//            table = try Self.getTable()
//        } catch let error {
//            onCompletion(nil, Self.convertError(error))
//            return
//        }
//
//        let query = Select(from: table)
//        Self.executeQuery(query: query, using: db, onCompletion)
//    }

    /// - Parameter matching: Optional QueryParams to use
    /// - Returns: An array of model
//    static func findAll<Q: QueryParams>(using db: Database? = nil, matching queryParams: Q? = nil, _ onCompletion: @escaping ([Self]?, RequestError?) -> Void) {
//        var table: Table
//        do {
//            table = try Self.getTable()
//        } catch let error {
//            onCompletion(nil, Self.convertError(error))
//            return
//        }
//
//        var query: Select = Select(from: table)
//        var parameters: [Any?]? = nil
//        if let queryParams = queryParams {
//            do {
//                (query, parameters) = try getSelectQueryWithFilters(query: query, queryParams: queryParams, table: table)
//            } catch let error {
//                onCompletion(nil, Self.convertError(error))
//                return
//            }
//        }
//        Self.executeQuery(query: query, parameters: parameters, using: db, onCompletion)
//    }
}

/**
 Extension of the RequestError from [KituraContracts](https://github.com/IBM-Swift/KituraContracts.git)
 */
extension RequestError {
    init(_ base: RequestError, reason: String) {
        self.init(rawValue: base.rawValue, reason: reason)
    }
    /// Error when the Database has not been set
    public static let ormDatabaseNotInitialized = RequestError(rawValue: 700, reason: "Database not Initialized")
    /// Error when the createTable call fails
    public static let ormTableCreationError = RequestError(rawValue: 701)
    /// Error when the TypeDecoder failed to extract the types from the model
    public static let ormCodableDecodingError = RequestError(rawValue: 702)
    /// Error when the DatabaseDecoder could not construct a Model
    public static let ormDatabaseDecodingError = RequestError(rawValue: 703)
    /// Error when the DatabaseEncoder could not decode a Model
    public static let ormDatabaseEncodingError = RequestError(rawValue: 704)
    /// Error when the Query fails to be executed
    public static let ormQueryError = RequestError(rawValue: 706)
    /// Error when the values retrieved from the database are nil
    public static let ormNotFound = RequestError(rawValue: 707)
    /// Error when the table defined does not contain a specific column
    public static let ormInvalidTableDefinition = RequestError(rawValue: 708)
    /// Error when the Identifier could not be constructed
    public static let ormIdentifierError = RequestError(rawValue: 709)
    /// Error when an internal error occurs
    public static let ormInternalError = RequestError(rawValue: 710)
    /// Error when retrieving a connection from the database fails
    public static let ormConnectionFailed = RequestError(rawValue: 711, reason: "Failed to retrieve a connection from the database")
}
