import Foundation
import XCTest
@testable import TimeMachinePlusPlus

final class LaunchAgentServiceTests: XCTestCase {
    func testPlistDataEscapesExecutablePath() throws {
        let data = try LaunchAgentService.plistData(
            label: "com.example.scan",
            executable: "/Applications/TimeMachine++ & Tools/TimeMachine++",
            intervalMinutes: 3
        )

        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        )
        let arguments = try XCTUnwrap(plist["ProgramArguments"] as? [String])

        XCTAssertEqual(arguments, ["/Applications/TimeMachine++ & Tools/TimeMachine++", "--background-scan"])
        XCTAssertEqual(plist["StartInterval"] as? Int, 5 * 60)
        XCTAssertEqual(plist["RunAtLoad"] as? Bool, true)
    }
}
