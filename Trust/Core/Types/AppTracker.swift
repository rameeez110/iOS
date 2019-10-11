// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.
import Foundation

final class AppTracker {
    struct Keys {
        static let launchCountTotal = "launchCountTotal"
        static let launchCountForCurrentBuild = "launchCountForCurrentBuild-" + String(Bundle.main.buildNumberInt)
        static let completedSharing = "completedSharing"
        static let completedRating = "completedRating"
        static let completeMultiCoinMigration = "completeMultiCoinMigrationKey"
    }

    let defaults: UserDefaults

    var launchCountTotal: Int {
        get { return defaults.integer(forKey: Keys.launchCountTotal) }
        set { defaults.set(newValue, forKey: Keys.launchCountTotal) }
    }

    var launchCountForCurrentBuild: Int {
        get { return defaults.integer(forKey: Keys.launchCountForCurrentBuild) }
        set { defaults.set(newValue, forKey: Keys.launchCountForCurrentBuild) }
    }

    var completedRating: Bool {
        get { return defaults.bool(forKey: Keys.completedRating) }
        set { defaults.set(newValue, forKey: Keys.completedRating) }
    }

    var completedSharing: Bool {
        get { return defaults.bool(forKey: Keys.completedSharing) }
        set { defaults.set(newValue, forKey: Keys.completedSharing) }
    }

    var completeMultiCoinMigration: Bool {
        get { return defaults.bool(forKey: Keys.completeMultiCoinMigration) }
        set { defaults.set(newValue, forKey: Keys.completeMultiCoinMigration) }
    }

    init(
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
    }

    func start() {
        launchCountTotal += 1
        launchCountForCurrentBuild += 1
    }

    var description: String {
        return """
        launchCountTotal: \(launchCountTotal)
        launchCountForCurrentBuild: \(launchCountForCurrentBuild)
        completedRating: \(completedRating)
        completedSharing: \(completedSharing)
        completeMultiCoinMigration: \(completeMultiCoinMigration)
        """
    }
}
