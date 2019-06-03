import XCTest

@testable import SwiftKueryORM
import Foundation
import KituraContracts

class TestTable: XCTestCase {
    static var allTests: [(String, (TestTable) -> () throws -> Void)] {
        return [
            ("testCreateTable", testCreateTable),
            ("testDropTable", testDropTable),
        ]
    }

    struct User: Model {
        var modelID: Int64?

        var username: String
        var password: String
    }

    /**
      Testing that the correct SQL Query is created to create a table
    */
    func testCreateTable() {
        let connection: TestConnection = createConnection(.returnEmpty)
        Database.default = Database(single: connection)
        performTest(asyncTasks: { expectation in
            ModelHandler.createTable(for: User.self) { result, error in
                XCTAssertNil(error, "Table Creation Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.raw, "Table Creation Failed: Query is nil")
                if let raw = connection.raw {
                let expectedQuery = "CREATE TABLE \"Users\" (\"modelID\" type AUTO_INCREMENT PRIMARY KEY, \"username\" type NOT NULL, \"password\" type NOT NULL)"
                  XCTAssertEqual(raw, expectedQuery, "Table Creation Failed: Invalid query")
                }
                expectation.fulfill()
            }
        })
    }

    /**
     Testing that the correct SQL Query is created to create a table when using a non-default database
     */
    func testCreateTableUsingDB() {
        let connection: TestConnection = createConnection(.returnEmpty)
        let db = Database(single: connection)
        performTest(asyncTasks: { expectation in
            ModelHandler.createTable(for: User.self, using: db) { result, error in
                XCTAssertNil(error, "Table Creation Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.raw, "Table Creation Failed: Query is nil")
                if let raw = connection.raw {
                    let expectedQuery = "CREATE TABLE \"Users\" (\"modelID\" type AUTO_INCREMENT PRIMARY KEY, \"username\" type NOT NULL, \"password\" type NOT NULL)"
                    XCTAssertEqual(raw, expectedQuery, "Table Creation Failed: Invalid query")
                }
                expectation.fulfill()
            }
        })
    }

    /**
      Testing that the correct SQL Query is created to drop a table
    */
    func testDropTable() {
        let connection: TestConnection = createConnection(.returnEmpty)
        Database.default = Database(single: connection)
        performTest(asyncTasks: { expectation in
            ModelHandler.dropTable(for: User.self) { result, error in
                XCTAssertNil(error, "Table Drop Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.query, "Table Drop Failed: Query is nil")
                if let query = connection.query {
                  let expectedQuery = "DROP TABLE \"Users\""
                  let resultQuery = connection.descriptionOf(query: query)
                  XCTAssertEqual(resultQuery, expectedQuery, "Table Drop Failed: Invalid query")
                }
                expectation.fulfill()
            }
        })
    }

    /**
     Testing that the correct SQL Query is created to drop a table when using a non-default database
     */
    func testDropTableUsingDB() {
        let connection: TestConnection = createConnection(.returnEmpty)
        let db = Database(single: connection)
        performTest(asyncTasks: { expectation in
            ModelHandler.dropTable(for: User.self, using: db) { result, error in
                XCTAssertNil(error, "Table Drop Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.query, "Table Drop Failed: Query is nil")
                if let query = connection.query {
                    let expectedQuery = "DROP TABLE \"Users\""
                    let resultQuery = connection.descriptionOf(query: query)
                    XCTAssertEqual(resultQuery, expectedQuery, "Table Drop Failed: Invalid query")
                }
                expectation.fulfill()
            }
        })
    }
}
