import XCTest

@testable import SwiftKueryORM
import Foundation
import KituraContracts

class TestId: XCTestCase {
    static var allTests: [(String, (TestId) -> () throws -> Void)] {
        return [
            ("testDelete", testDelete),
            ("testNilIDInsert", testNilIDInsert),
        ]
    }

    struct Person: Model {
        var modelID: Int64?

        var name: String
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
      Testing that the correct SQL Query is created to delete a specific model
    */
    func testDelete() {
        let connection: TestConnection = createConnection()
        Database.default = Database(single: connection)
        performTest(asyncTasks: { expectation in
            let person = Person(modelID: 1, name: "Joe", age: 38)
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

    struct IdentifiedPerson: Model {
        var modelID: Int64?

        var name: String
        var age: Int
    }

    func testNilIDInsert() {
        let connection: TestConnection = createConnection(.returnOneRow) //[1, "Joe", Int32(38)]
        Database.default = Database(single: connection)
        performTest(asyncTasks: { expectation in
            let myIPerson = IdentifiedPerson(modelID: nil, name: "Joe", age: 38)
            ModelHandler.save(instance: myIPerson, of: IdentifiedPerson.self) { identifiedPerson, error in
                XCTAssertNil(error, "Error on IdentifiedPerson.save")
                if let newPerson = identifiedPerson {
                    XCTAssertEqual(newPerson.modelID, 1, "Id not stored on IdentifiedPerson")
                }
                expectation.fulfill()
            }
        })
    }
}
