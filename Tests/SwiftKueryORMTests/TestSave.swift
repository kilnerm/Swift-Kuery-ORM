import XCTest

@testable import SwiftKueryORM
import Foundation
import KituraContracts

/*
  Function to extract the captured groups from a Regex match operation:
  https://samwize.com/2016/07/21/how-to-capture-multiple-groups-in-a-regex-with-swift/
**/
extension String {
    func capturedGroups(withRegex pattern: String) -> [String] {
        var results = [String]()

        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return results
        }

        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.count))

        guard let match = matches.first else { return results }

        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }

        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)
            let nsString = NSString(string: self)
            let matchedString = nsString.substring(with: capturedGroupIndex)
            results.append(matchedString)
        }

        return results
    }
}

class TestSave: XCTestCase {
    static var allTests: [(String, (TestSave) -> () throws -> Void)] {
        return [
            ("testSave", testSave),
        ]
    }

    struct Person: Model {
        var modelID: Int64?

        var name: String
        var age: Int
    }
    /**
      Testing that the correct SQL Query is created to save a Model
    */
    func testSave() {
        let connection: TestConnection = createConnection(.returnOneRow)
        Database.default = Database(single: connection)
        performTest(asyncTasks: { expectation in
            let person = Person(modelID: nil, name: "Joe", age: 38)
            ModelHandler.save(instance: person) { p, error in
                XCTAssertNil(error, "Save Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.query, "Save Failed: Query is nil")
                if let query = connection.query {
                  let expectedPrefix = "INSERT INTO \"Persons\""
                  let expectedSQLStatement = "VALUES"
                  let expectedDictionary = ["\"name\"": "?1,?2", "\"age\"": "?1,?2"]

                  let resultQuery = connection.descriptionOf(query: query)
                  XCTAssertTrue(resultQuery.hasPrefix(expectedPrefix))
                  XCTAssertTrue(resultQuery.contains(expectedSQLStatement))
                  self.verifyColumnsAndValues(resultQuery: resultQuery, expectedDictionary: expectedDictionary)
                }
                XCTAssertNotNil(p, "Save Failed: No model returned")
                if let p = p {
                    XCTAssertEqual(p.name, person.name, "Save Failed: \(String(describing: p.name)) is not equal to \(String(describing: person.name))")
                    XCTAssertEqual(p.age, person.age, "Save Failed: \(String(describing: p.age)) is not equal to \(String(describing: person.age))")
                }
                expectation.fulfill()
            }
        })
    }

    /**
     Testing that the correct SQL Query is created to save a Model when using a non-default database
     */
    func testSaveUsingDB() {
        let connection: TestConnection = createConnection(.returnOneRow)
        let db = Database(single: connection)
        performTest(asyncTasks: { expectation in
            let person = Person(modelID: nil, name: "Joe", age: 38)
            ModelHandler.save(instance: person, using: db) { p, error in
                XCTAssertNil(error, "Save Failed: \(String(describing: error))")
                XCTAssertNotNil(connection.query, "Save Failed: Query is nil")
                if let query = connection.query {
                    let expectedPrefix = "INSERT INTO \"Persons\""
                    let expectedSQLStatement = "VALUES"
                    let expectedDictionary = ["\"name\"": "?1,?2", "\"age\"": "?1,?2"]

                    let resultQuery = connection.descriptionOf(query: query)
                    XCTAssertTrue(resultQuery.hasPrefix(expectedPrefix))
                    XCTAssertTrue(resultQuery.contains(expectedSQLStatement))
                    self.verifyColumnsAndValues(resultQuery: resultQuery, expectedDictionary: expectedDictionary)
                }
                XCTAssertNotNil(p, "Save Failed: No model returned")
                if let p = p {
                    XCTAssertEqual(p.name, person.name, "Save Failed: \(String(describing: p.name)) is not equal to \(String(describing: person.name))")
                    XCTAssertEqual(p.age, person.age, "Save Failed: \(String(describing: p.age)) is not equal to \(String(describing: person.age))")
                }
                expectation.fulfill()
            }
        })
    }

    private func verifyColumnsAndValues(resultQuery: String, expectedDictionary: [String: String]) {
      //Regex to extract the columns and values of an insert
      //statement, such as:
      //INSERT into table (columns) VALUES (values)
      let regexPattern = ".*\\((.*)\\)[^\\(\\)]*\\((.*)\\)"
      let groups = resultQuery.capturedGroups(withRegex: regexPattern)
      XCTAssertEqual(groups.count, 2)

      // Extracting the columns and values from the captured groups
      let columns = groups[0].filter { $0 != " " }.split(separator: ",")
      let values = groups[1].filter { $0 != " " && $0 != "'" }.split(separator: ",")
      // Creating the result dictionary [Column: Value]
      var resultDictionary: [String: String] = [:]
      for (column, value) in zip(columns, values) {
        resultDictionary[String(column)] = String(value)
      }

      // Asserting the results which the expectations
      XCTAssertEqual(resultDictionary.count, expectedDictionary.count)
      for (key, value) in expectedDictionary {
        XCTAssertNotNil(resultDictionary[key], "Value for key: \(String(describing: key)) is nil in the result dictionary")
        let values = value.split(separator: ",")
        var success = false
        for value in values where resultDictionary[key] == String(value) {
          success = true
        }
        XCTAssertTrue(success)
      }
    }
}
