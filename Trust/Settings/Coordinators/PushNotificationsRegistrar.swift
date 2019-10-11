// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import Foundation
import Moya
import TrustCore
import UIKit
import UserNotifications

final class PushNotificationsRegistrar {
    private let provider = TrustProviderFactory.makeProvider()
    let config = Config()

    var isRegisteredForRemoteNotifications: Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }

    func reRegister() {
        guard isRegisteredForRemoteNotifications else { return }
        register()
    }

    func register() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in }
        UIApplication.shared.registerForRemoteNotifications()
    }

    func unregister() {
        let device = PushDevice(
            deviceID: UIDevice.current.identifierForVendor!.uuidString,
            token: "",
            networks: [:],
            preferences: NotificationsViewController.getPreferences()
        )

        provider.request(.unregister(device: device)) { _ in }

        UIApplication.shared.unregisterForRemoteNotifications()
    }

    func didRegister(with deviceToken: Data, networks: [Int: [String]]) {
        let token = deviceToken.map { data -> String in
            String(format: "%02.2hhx", data)
        }.joined()

        let device = PushDevice(
            deviceID: UIDevice.current.identifierForVendor!.uuidString,
            token: token,
            networks: networks,
            preferences: NotificationsViewController.getPreferences()
        )

        provider.request(.register(device: device)) { _ in }
    }
}
