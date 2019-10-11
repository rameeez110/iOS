// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import Foundation

enum OperationType: String {
    case tokenTransfer = "token_transfer"
    case unknown

    init(string: String) {
        self = OperationType(rawValue: string) ?? .unknown
    }
}

extension OperationType: Decodable {}
