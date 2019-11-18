// Copyright DApps Platform Inc. All rights reserved.

import Eureka
import UIKit

struct NotificationChange: Codable {
    let isEnabled: Bool
    let preferences: Preferences
}

enum NotificationChanged {
    case state(isEnabled: Bool)
    case preferences(Preferences)
}

final class NotificationsViewController: FormViewController {
    private let viewModel = NotificationsViewModel()
    private let preferencesController: PreferencesController

    private struct Keys {
        static let pushNotifications = "pushNotifications"
        static let payment = "payment"
    }

    var didChange: ((_ change: NotificationChanged) -> Void)?

    private static var isPushNotificationEnabled: Bool {
        guard let settings = UIApplication.shared.currentUserNotificationSettings else { return false }
        return UIApplication.shared.isRegisteredForRemoteNotifications && !settings.types.isEmpty
    }

    private var showOptionsCondition: Condition {
        return Condition.predicate(NSPredicate(format: "$\(Keys.pushNotifications) == false"))
    }

    init(
        preferencesController: PreferencesController = PreferencesController()
    ) {
        self.preferencesController = preferencesController
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = viewModel.title

        form +++ Section()

            <<< SwitchRow(Keys.pushNotifications) {
                $0.title = NSLocalizedString("settings.allowPushNotifications.button.title", value: "Allow Push Notifications", comment: "")
                $0.value = NotificationsViewController.isPushNotificationEnabled
            }.onChange { [unowned self] row in
                self.didChange?(.state(isEnabled: row.value ?? false))
            }.cellUpdate { cell, _ in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.textColor = .black
                if #available(iOS 13.0, *) {
                    // use the feature only available in iOS 9
                    // for ex. UIStackView
                    cell.textLabel?.textColor = .label
                }
            }

            +++ Section(
                footer: NSLocalizedString(
                    "settings.pushNotifications.allowPushNotifications.footer",
                    value: "You will be notified for sent and received transactions.",
                    comment: ""
                )
            ) {
                $0.hidden = showOptionsCondition
            }

            <<< SwitchRow(Keys.payment) { [weak self] in
                $0.title = NSLocalizedString("settings.pushNotifications.payment.button.title", value: "Sent and Receive", comment: "")
                $0.value = true
                $0.hidden = self?.showOptionsCondition
                $0.disabled = Condition(booleanLiteral: true)
            }.cellSetup { cell, _ in
                cell.switchControl.isEnabled = false
            }.cellUpdate { cell, _ in
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.textColor = .black
                if #available(iOS 13.0, *) {
                    // use the feature only available in iOS 9
                    // for ex. UIStackView
                    cell.textLabel?.textColor = .label
                }
            }
    }

    func updatePreferences() {
        didChange?(.preferences(
            NotificationsViewController.getPreferences()
        ))
    }

    static func getPreferences() -> Preferences {
        // let preferencesController = PreferencesController()
        let preferences = Preferences()
        return preferences
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
