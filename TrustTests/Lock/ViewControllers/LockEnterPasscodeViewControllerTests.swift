// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import KeychainSwift
@testable import Trust
import XCTest

class LockEnterPasscodeViewControllerTests: XCTestCase {
    let passcode = "123456"
    let incorrectPasscode = "111111"

    func testCorrectPasscodeInput() {
        let lock = Lock(keychain: KeychainSwift(keyPrefix: Constants.keychainTestsKeyPrefix))
        let lockViewModel = LockEnterPasscodeViewModel(lock: lock)
        let vc = LockEnterPasscodeViewController(model: lockViewModel, lock: lock)
        vc.configureLockView()
        vc.configureInvisiblePasscodeField()

        lock.setPasscode(passcode: passcode)

        vc.enteredPasscode(passcode)

        XCTAssertTrue(lock.numberOfAttempts() == 0)
    }

    func testIncorrectPasscodeInput() {
        let lock = Lock(keychain: KeychainSwift(keyPrefix: Constants.keychainTestsKeyPrefix))
        let lockViewModel = LockEnterPasscodeViewModel(lock: lock)
        let vc = LockEnterPasscodeViewController(model: lockViewModel, lock: lock)
        vc.configureLockView()
        vc.configureInvisiblePasscodeField()

        lock.setPasscode(passcode: passcode)

        vc.enteredPasscode(incorrectPasscode)

        XCTAssertTrue(lock.numberOfAttempts() > 0)
    }

    func testIncorrectPasscodeLimitInput() {
        let lock = Lock(keychain: KeychainSwift(keyPrefix: Constants.keychainTestsKeyPrefix))

        XCTAssertFalse(lock.incorrectMaxAttemptTimeIsSet())

        let lockViewModel = LockEnterPasscodeViewModel(lock: lock)
        let vc = LockEnterPasscodeViewController(model: lockViewModel, lock: lock)
        vc.configureLockView()
        vc.configureInvisiblePasscodeField()

        lock.setPasscode(passcode: passcode)

        while lock.numberOfAttempts() <= lockViewModel.passcodeAttemptLimit() {
            vc.enteredPasscode(incorrectPasscode)
        }

        XCTAssertTrue(lock.incorrectMaxAttemptTimeIsSet())
    }
}
