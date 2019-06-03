import XCTest

@testable import SwiftKueryORM
import Foundation
import KituraContracts

class TestUpdate: XCTestCase {
    static var allTests: [(String, (TestUpdate) -> () throws -> Void)] {
        return [
            ("testUpdate", testUpdate),
            ("testUpdateWithNilValue", testUpdateWithNilValue),
        ]
    }

    struct Person: Model {
        var modelID: Int64?

        var name: String?
        var age: Int
    }

    /**
      Testing that the correct SQL Query is created to update a specific model.
    */
    func testUpdate() {
        let connection: TestConnection = createConnection()
        Database.default = Database(single: connection)
        performTest(asyncTasks: { expectation in
            let person = Person(modelID: 1, name: "Joe", age: 38)
            ModelHandler.update(instance: person, of: Person.self) { p, error in
                XCTAssertNil(error, "Update Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.query, "Update Failed: Query is nil")
                if let query = connection.query {
                  let expectedPrefix = "UPDATE \"Persons\" SET"
                  let expectedSuffix = "WHERE \"Persons\".\"modelID\" = ?3"
                  let expectedUpdates = [["\"name\" = ?1", "\"name\" = ?2"], ["\"age\" = ?1", "\"age\" = ?2"]]
                  let resultQuery = connection.descriptionOf(query: query)
                  XCTAssertTrue(resultQuery.hasPrefix(expectedPrefix))
                  XCTAssertTrue(resultQuery.hasSuffix(expectedSuffix))
                  for updates in expectedUpdates {
                      var success = false
                      for update in updates where resultQuery.contains(update) {
                        success = true
                      }
                      XCTAssertTrue(success)
                  }
                }
                XCTAssertNotNil(p, "Update Failed: No model returned")
                if let p = p {
                    XCTAssertEqual(p.name, person.name, "Update Failed: \(String(describing: p.name)) is not equal to \(String(describing: person.name))")
                    XCTAssertEqual(p.age, person.age, "Update Failed: \(String(describing: p.age)) is not equal to \(String(describing: person.age))")
                }
                expectation.fulfill()
            }
        })
    }

    /**
      Testing that the correct SQL Query is created to update a specific model with one of the values being nil.
    */
    func testUpdateWithNilValue() {
        let connection: TestConnection = createConnection()
        Database.default = Database(single: connection)
        performTest(asyncTasks: { expectation in
            let person = Person(modelID: 1, name: nil, age: 38)
            ModelHandler.update(instance: person, of: Person.self) { p, error in
                XCTAssertNil(error, "Update Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.query, "Update Failed: Query is nil")
                if let query = connection.query {
                  let expectedPrefix = "UPDATE \"Persons\" SET"
                  let expectedSuffix = "WHERE \"Persons\".\"modelID\" = ?3"
                  let expectedUpdates = [["\"name\" = ?1", "\"name\" = ?2"], ["\"age\" = ?1", "\"age\" = ?2"]]
                  let resultQuery = connection.descriptionOf(query: query)
                  XCTAssertTrue(resultQuery.hasPrefix(expectedPrefix))
                  XCTAssertTrue(resultQuery.hasSuffix(expectedSuffix))
                  for updates in expectedUpdates {
                      var success = false
                      for update in updates where resultQuery.contains(update) {
                        success = true
                      }
                      XCTAssertTrue(success)
                  }
                }

                XCTAssertNotNil(p, "Update Failed: No model returned")
                if let p = p {
                    XCTAssertEqual(p.name, person.name, "Update Failed: \(String(describing: p.name)) is not equal to \(String(describing: person.name))")
                    XCTAssertEqual(p.age, person.age, "Update Failed: \(String(describing: p.age)) is not equal to \(String(describing: person.age))")
                }
                expectation.fulfill()
            }
        })
    }
}
