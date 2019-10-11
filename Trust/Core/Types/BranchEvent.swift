// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import Foundation
import TrustCore

enum BranchEventName: String {
    case openURL
    case newToken
}

enum BranchEvent {
    case openURL(URL)
    case newToken(Address)

    var params: [String: String] {
        switch self {
        case let .openURL(url):
            let urlString = url.absoluteString
            return [
                "url": urlString,
                "$canonical_url": urlString,
                "~campaign": "trust-ios-browser-sharing",
                "~channel": "trust-ios-browser-sharing",
                "event": BranchEventName.openURL.rawValue,
            ]
        case let .newToken(address):
            return [
                "contract": address.description,
                "event": BranchEventName.newToken.rawValue,
            ]
        }
    }
}

extension BranchEvent: Equatable {
    static func == (lhs: BranchEvent, rhs: BranchEvent) -> Bool {
        switch (lhs, rhs) {
        case let (.openURL(lhs), .openURL(rhs)):
            return lhs == rhs
        case let (.newToken(lhs), .newToken(rhs)):
            return lhs.description == rhs.description
        case (_, .openURL),
             (_, .newToken):
            return false
        }
    }
}
