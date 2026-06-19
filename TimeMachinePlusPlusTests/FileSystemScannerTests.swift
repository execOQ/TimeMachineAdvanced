import XCTest
@testable import TimeMachinePlusPlus

final class FileSystemScannerTests: XCTestCase {
    func testScannerMatchesPatternDirectoryAndSkipsDescendants() throws {
        let root = FileManager.default.temporaryDirectory.standardizedFileURL
            .appendingPathComponent("TimeMachinePlusPlusTests-\(UUID().uuidString)", isDirectory: true)
        let nodeModules = root.appendingPathComponent("project/node_modules", isDirectory: true)
        let nested = nodeModules.appendingPathComponent("left-pad", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let settings = AppSettings(
            scanRoots: [root.path],
            scanIntervalMinutes: AppSettings.dailyScanIntervalMinutes,
            maxDepth: 8
        )
        let rule = RegexRule(name: "Node", pattern: "node_modules/", kind: .pattern)

        let matches = FileSystemScanner().scan(settings: settings, rules: [rule])

        XCTAssertTrue(matches.keys.contains { $0.path == nodeModules.path })
        XCTAssertFalse(matches.keys.contains { $0.path == nested.path })
    }

    func testScannerCanPreviewOneRuleOnly() throws {
        let root = FileManager.default.temporaryDirectory.standardizedFileURL
            .appendingPathComponent("TimeMachinePlusPlusRulePreview-\(UUID().uuidString)", isDirectory: true)
        let nodeModules = root.appendingPathComponent("project/node_modules", isDirectory: true)
        let build = root.appendingPathComponent("project/build", isDirectory: true)
        try FileManager.default.createDirectory(at: nodeModules, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: build, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let settings = AppSettings(
            scanRoots: [root.path],
            scanIntervalMinutes: AppSettings.dailyScanIntervalMinutes,
            maxDepth: 8
        )

        let matches = FileSystemScanner().scan(
            settings: settings,
            rule: RegexRule(name: "Build", pattern: "build/", kind: .pattern)
        )

        XCTAssertEqual(matches.map(\.path), [build.path])
    }

    func testScannerPrunesIgnoredPaths() throws {
        let root = FileManager.default.temporaryDirectory.standardizedFileURL
            .appendingPathComponent("TimeMachinePlusPlusIgnored-\(UUID().uuidString)", isDirectory: true)
        let ignoredBuild = root.appendingPathComponent("ignored/project/build", isDirectory: true)
        let includedBuild = root.appendingPathComponent("included/project/build", isDirectory: true)
        try FileManager.default.createDirectory(at: ignoredBuild, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: includedBuild, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let settings = AppSettings(
            scanRoots: [root.path],
            ignoredPaths: [root.appendingPathComponent("ignored", isDirectory: true).path],
            scanIntervalMinutes: AppSettings.dailyScanIntervalMinutes,
            maxDepth: 8
        )

        let matches = FileSystemScanner().scan(
            settings: settings,
            rule: RegexRule(name: "Build", pattern: "build/", kind: .pattern)
        )

        XCTAssertEqual(matches.map(\.path), [includedBuild.path])
    }
}
