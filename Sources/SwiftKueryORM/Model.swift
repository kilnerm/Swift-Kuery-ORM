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

    @discardableResult
    static func createTableSync(using db: Database? = nil) throws -> Bool {
        return try ModelHandler.createTableSync(for: Self.self, using: db)
    }

    static func createTable(using db: Database? = nil, _ onCompletion: @escaping (Bool?, RequestError?) -> Void) {
        ModelHandler.createTable(for: Self.self, using: db, onCompletion)
    }

    @discardableResult
    static func dropTableSync(using db: Database? = nil) throws -> Bool {
        return try ModelHandler.dropTableSync(for: Self.self, using: db)
    }

    static func dropTable(using db : Database? = nil, _ onCompletion: @escaping (Bool?, RequestError?) -> Void) {
        ModelHandler.dropTable(for: Self.self, using: db, onCompletion)
    }

    func save(using db: Database? = nil, _ onCompletion: @escaping (Self?, RequestError?) -> Void) {
        ModelHandler.save(instance: self, onCompletion)
    }

    func update(using db: Database? = nil, _ onCompletion: @escaping (Self?, RequestError?) -> Void) {
        ModelHandler.update(instance: self, using: db, onCompletion)
    }

    func delete(using db: Database? = nil, _ onCompletion: @escaping (RequestError?) -> Void) {
        ModelHandler.delete(instance: self, onCompletion)
    }

    static func deleteAll(using db: Database? = nil, _ onCompletion: @escaping (RequestError?) -> Void) {
        ModelHandler.deleteAll(of: Self.self, using: db, onCompletion)
    }

    static func deleteAll<Q: QueryParams>(using db: Database? = nil, matching queryParams: Q?, _ onCompletion: @escaping (RequestError?) -> Void) {
        ModelHandler.deleteAll(of: Self.self, using: db, matching: queryParams, onCompletion)
    }

    static func find(id: Int64, using db: Database? = nil, _ onCompletion: @escaping (Self?, RequestError?) -> Void) {
        ModelHandler.find(instance: id, using: db, onCompletion)
    }

    static func findAll(using db: Database? = nil, _ onCompletion: @escaping ([Self]?, RequestError?) -> Void) {
        ModelHandler.findAll(using: db, onCompletion)
    }

    static func findAll<Q: QueryParams>(using db: Database? = nil, matching queryParams: Q? = nil, _ onCompletion: @escaping ([Self]?, RequestError?) -> Void) {
        ModelHandler.findAll(using: db, matching: queryParams, onCompletion)
    }
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
