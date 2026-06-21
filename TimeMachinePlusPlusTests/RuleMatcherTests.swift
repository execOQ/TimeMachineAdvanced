import XCTest
@testable import TimeMachinePlusPlus

final class RuleMatcherTests: XCTestCase {
    func testRegexValidatorRejectsInvalidPattern() {
        let validRule = RegexRule(name: "Regex", pattern: #"/node_modules($|/)"#, kind: .regex)
        let invalidRule = RegexRule(name: "Broken", pattern: "[", kind: .regex)

        XCTAssertNil(RuleMatcher.validationError(for: validRule))
        XCTAssertNotNil(RuleMatcher.validationError(for: invalidRule))
    }

    func testPatternRuleMatchesDirectoryPattern() {
        let rule = RegexRule(name: "Build", pattern: "build/", kind: .pattern)

        XCTAssertTrue(RuleMatcher.matches(path: "/Users/me/project/build", isDirectory: true, rule: rule))
        XCTAssertFalse(RuleMatcher.matches(path: "/Users/me/project/build.log", isDirectory: false, rule: rule))
    }

    func testPatternRuleAcceptsMultipleDirectoryPatterns() {
        let rule = RegexRule(name: "Virtualenvs", pattern: ".venv/\nvenv/", kind: .pattern)

        XCTAssertTrue(RuleMatcher.matches(path: "/Users/me/app/.venv", isDirectory: true, rule: rule))
        XCTAssertTrue(RuleMatcher.matches(path: "/Users/me/app/venv", isDirectory: true, rule: rule))
        XCTAssertFalse(RuleMatcher.matches(path: "/Users/me/app/venv.txt", isDirectory: false, rule: rule))
    }

    func testPathRuleMatchesStandardizedPath() {
        let rule = RegexRule(name: "Cache", pattern: "/Users/me/project/../project/cache", kind: .path)

        XCTAssertTrue(RuleMatcher.matches(path: "/Users/me/project/cache", isDirectory: true, rule: rule))
    }
}
