import Foundation
import IOKit.pwr_mgt

final class SleepPreventionManager: @unchecked Sendable {
    private var assertionID: IOPMAssertionID = 0

    var isActive: Bool { assertionID != 0 }

    func start() {
        guard assertionID == 0 else { return }
        let reason = "Preventing sleep for remote access" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result != kIOReturnSuccess {
            assertionID = 0
        }
    }

    func stop() {
        guard assertionID != 0 else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
    }

    deinit {
        stop()
    }
}
