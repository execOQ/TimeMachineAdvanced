import XCTest
@testable import TimeMachinePlusPlus

@MainActor
final class AccessScanTests: XCTestCase {
    func testPatternScanWithoutFullDiskAccessProducesNoMatches() async {
        let store = AppStateStore(timeMachine: FakeTimeMachineClient())
        store.settings = AppSettings(
            scanRoots: [],
            onboardingCompleted: true,
            scanIntervalMinutes: AppSettings.dailyScanIntervalMinutes,
            maxDepth: 7
        )
        store.fullDiskAccessStatus = .missing
        store.rules = [RegexRule(name: "Build", pattern: "build/", kind: .pattern)]

        await store.scanNow()

        XCTAssertEqual(store.matches, [])
        XCTAssertEqual(store.accessWarning, .fullDiskAccessMissing)
    }

    func testExactPathRulesRemainUsableWithoutFullDiskAccess() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("TimeMachinePlusPlusPath-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = AppStateStore(timeMachine: FakeTimeMachineClient())
        store.settings = AppSettings(
            scanRoots: [],
            onboardingCompleted: true,
            scanIntervalMinutes: AppSettings.dailyScanIntervalMinutes,
            maxDepth: 7
        )
        store.fullDiskAccessStatus = .missing
        store.rules = [RegexRule(name: "Exact", pattern: root.path, kind: .path)]

        await store.scanNow()

        XCTAssertEqual(store.matches.map(\.path), [root.path])
    }
}

private struct FakeTimeMachineClient: TimeMachineClient {
    func addExclusion(path: String) throws -> CommandResult {
        CommandResult(exitCode: 0, output: "", errorOutput: "")
    }

    func removeExclusion(path: String) throws -> CommandResult {
        CommandResult(exitCode: 0, output: "", errorOutput: "")
    }

    func isExcluded(path: String) throws -> Bool {
        false
    }
}
