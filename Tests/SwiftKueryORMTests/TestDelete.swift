import XCTest

@testable import SwiftKueryORM
import Foundation
import KituraContracts

class TestDelete: XCTestCase {
    static var allTests: [(String, (TestDelete) -> () throws -> Void)] {
        return [
            ("testDeleteWithId", testDeleteWithId),
            ("testDeleteAll", testDeleteAll),
            ("testDeleteAllMatching", testDeleteAllMatching),
        ]
    }

    struct Person: Model {
        var modelID: Int64?

        var name: String
        var age: Int
    }

    /**
      Testing that the correct SQL Query is created to delete a specific model
    */
    func testDeleteWithId() {
        let connection: TestConnection = createConnection()
        Database.default = Database(single: connection)
        performTest(asyncTasks: { expectation in
            let person = Person(modelID: 1, name: "any", age: 0)
            ModelHandler.delete(instance: person, of: Person.self) { error in
                XCTAssertNil(error, "Delete Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.query, "Delete Failed: Query is nil")
                if let query = connection.query {
                  let expectedQuery = "DELETE FROM \"Persons\" WHERE \"Persons\".\"modelID\" = ?1"
                  let resultQuery = connection.descriptionOf(query: query)
                  XCTAssertEqual(resultQuery, expectedQuery, "Expected query \(String(describing: expectedQuery)) did not match result query: \(String(describing: resultQuery))")
                }
                expectation.fulfill()
            }
        })
    }

    /**
      Testing that the correct SQL Query is created to delete all model
    */
    func testDeleteAll() {
        let connection: TestConnection = createConnection()
        Database.default = Database(single: connection)
        performTest(asyncTasks: { expectation in
            ModelHandler.deleteAll(of: Person.self) { error in
                XCTAssertNil(error, "Delete Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.query, "Delete Failed: Query is nil")
                if let query = connection.query {
                  let expectedQuery = "DELETE FROM \"Persons\""
                  let resultQuery = connection.descriptionOf(query: query)
                  XCTAssertEqual(resultQuery, expectedQuery, "Expected query \(String(describing: expectedQuery)) did not match result query: \(String(describing: resultQuery))")
                }
                expectation.fulfill()
            }
        })
    }

    struct Filter: QueryParams {
      let name: String
      let age: Int
    }

    /**
      Testing that the correct SQL Query is created to delete all model matching the QueryParams
    */
    func testDeleteAllMatching() {
        let connection: TestConnection = createConnection()
        Database.default = Database(single: connection)
        let filter = Filter(name: "Joe", age: 38)
        performTest(asyncTasks: { expectation in
            ModelHandler.deleteAll(of: Person.self, matching: filter) { error in
                XCTAssertNil(error, "Delete Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.query, "Delete Failed: Query is nil")
                if let query = connection.query {
                  let expectedPrefix = "DELETE FROM \"Persons\" WHERE"
                  let expectedClauses = [["\"Persons\".\"name\" = ?1", "\"Persons\".\"name\" = ?2"], ["\"Persons\".\"age\" = ?1", "\"Persons\".\"age\" = ?2"]]
                  let expectedOperator = "AND"
                  let resultQuery = connection.descriptionOf(query: query)
                  XCTAssertTrue(resultQuery.hasPrefix(expectedPrefix))
                  for whereClauses in expectedClauses {
                    var success = false
                    for whereClause in whereClauses where resultQuery.contains(whereClause) {
                      success = true
                    }
                    XCTAssertTrue(success)
                  }
                  XCTAssertTrue(resultQuery.contains(expectedOperator))
                }
                expectation.fulfill()
            }
        })
    }
}
