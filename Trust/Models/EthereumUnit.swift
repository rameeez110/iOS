// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import Foundation

public enum EthereumUnit: Int64 {
    case wei = 1
    case kwei = 1000
    case gwei = 1_000_000_000
    case ether = 1_000_000_000_000_000_000
}

extension EthereumUnit {
    var name: String {
        switch self {
        case .wei: return "Wei"
        case .kwei: return "Kwei"
        case .gwei: return "Gwei"
        case .ether: return "Ether"
        }
    }
}

// https://github.com/ethereumjs/ethereumjs-units/blob/master/units.json
