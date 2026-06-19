import XCTest
@testable import TimeMachinePlusPlus

final class AppSettingsTests: XCTestCase {
    func testBackgroundHelperDefaultsToDaily() {
        XCTAssertEqual(AppSettings.defaults.scanIntervalMinutes, AppSettings.dailyScanIntervalMinutes)
    }

    func testQuickPreviewLimitDefaultsToTwentyFive() {
        XCTAssertEqual(AppSettings.defaults.previewResultLimit, 25)
    }

    func testAutomaticUpdateChecksDefaultToOn() {
        XCTAssertTrue(AppSettings.defaults.automaticallyChecksForUpdates)
    }

    func testScanRootsDefaultToNoAdditionalRoots() {
        XCTAssertEqual(AppSettings.defaults.scanRoots, [])
    }

    func testIgnoredPathsDefaultToKnownNoisyHomeFolders() {
        let home = PathNormalizer.normalized(FileManager.default.homeDirectoryForCurrentUser)

        XCTAssertEqual(
            AppSettings.defaults.ignoredPaths,
            [
                "\(home)/.Trash",
                "\(home)/Applications",
                "\(home)/Downloads",
                "\(home)/Music/iTunes",
                "\(home)/Music/Music",
                "\(home)/Pictures/Photos Library.photoslibrary"
            ]
        )
    }

    func testSettingsDecodeOldHomeOnlyStateRequiresOnboarding() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let json = """
        {
          "scanRoots": ["\(home)"],
          "backgroundScanningEnabled": true,
          "scanIntervalMinutes": 1440,
          "maxDepth": 7
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertFalse(settings.onboardingCompleted)
        XCTAssertEqual(settings.scanRoots, [])
        XCTAssertEqual(settings.ignoredPaths, AppSettings.defaultIgnoredPaths.map(PathNormalizer.normalized))
    }

    func testSettingsDecodeOldCustomRootsWithoutCompletingOnboarding() throws {
        let json = """
        {
          "scanRoots": ["/Users/me/Projects"],
          "backgroundScanningEnabled": true,
          "scanIntervalMinutes": 1440,
          "maxDepth": 7
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertFalse(settings.onboardingCompleted)
        XCTAssertEqual(settings.scanRoots, ["/Users/me/Projects"])
        XCTAssertEqual(settings.previewResultLimit, AppSettings.defaultPreviewResultLimit)
        XCTAssertTrue(settings.automaticallyChecksForUpdates)
        XCTAssertEqual(settings.ignoredPaths, AppSettings.defaultIgnoredPaths.map(PathNormalizer.normalized))
    }

    func testSettingsDecodeOldMixedRootsAsAdditionalScanRoots() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let json = """
        {
          "scanRoots": ["\(home)", "/Users/me/Projects"],
          "scanIntervalMinutes": 1440,
          "maxDepth": 7
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertFalse(settings.onboardingCompleted)
        XCTAssertEqual(settings.scanRoots, ["/Users/me/Projects"])
    }

    func testSettingsDecodePersistedIgnoredPaths() throws {
        let json = """
        {
          "scanRoots": ["/Users/me/Projects"],
          "ignoredPaths": ["/Users/me/Projects/.build", "/Users/me/Projects/node_modules"],
          "scanIntervalMinutes": 1440,
          "maxDepth": 7
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.ignoredPaths, ["/Users/me/Projects/.build", "/Users/me/Projects/node_modules"])
    }
}
