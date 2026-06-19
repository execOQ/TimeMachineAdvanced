import XCTest
@testable import TimeMachinePlusPlus

final class AccessResolverTests: XCTestCase {
    func testFullDiskAccessGrantedUsesHomeRoot() {
        let settings = AppSettings(
            scanRoots: [],
            onboardingCompleted: true,
            scanIntervalMinutes: AppSettings.dailyScanIntervalMinutes,
            maxDepth: 7
        )

        let roots = ScanAccessResolver.activeScanRoots(settings: settings, fullDiskAccessStatus: .granted)

        XCTAssertEqual(roots, [PathNormalizer.normalized(FileManager.default.homeDirectoryForCurrentUser)])
        XCTAssertNil(ScanAccessResolver.warning(settings: settings, fullDiskAccessStatus: .granted))
    }

    func testFullDiskAccessGrantedIncludesAdditionalScanRoots() {
        let settings = AppSettings(
            scanRoots: ["/Volumes/Archive", "/Network/Share"],
            onboardingCompleted: true,
            scanIntervalMinutes: AppSettings.dailyScanIntervalMinutes,
            maxDepth: 7
        )

        let roots = ScanAccessResolver.activeScanRoots(settings: settings, fullDiskAccessStatus: .granted)

        XCTAssertEqual(
            roots,
            [
                PathNormalizer.normalized(FileManager.default.homeDirectoryForCurrentUser),
                "/Volumes/Archive",
                "/Network/Share"
            ]
        )
    }

    func testFullDiskAccessMissingHasNoRootsAndWarning() {
        let settings = AppSettings(
            scanRoots: [],
            onboardingCompleted: true,
            scanIntervalMinutes: AppSettings.dailyScanIntervalMinutes,
            maxDepth: 7
        )

        XCTAssertEqual(ScanAccessResolver.activeScanRoots(settings: settings, fullDiskAccessStatus: .missing), [])
        XCTAssertEqual(ScanAccessResolver.warning(settings: settings, fullDiskAccessStatus: .missing), .fullDiskAccessMissing)
    }

    func testFullDiskAccessMissingStillIncludesAdditionalScanRoots() {
        let settings = AppSettings(
            scanRoots: ["/Volumes/Archive"],
            onboardingCompleted: true,
            scanIntervalMinutes: AppSettings.dailyScanIntervalMinutes,
            maxDepth: 7
        )

        XCTAssertEqual(ScanAccessResolver.activeScanRoots(settings: settings, fullDiskAccessStatus: .missing), ["/Volumes/Archive"])
        XCTAssertEqual(ScanAccessResolver.warning(settings: settings, fullDiskAccessStatus: .missing), .fullDiskAccessMissing)
    }
}
