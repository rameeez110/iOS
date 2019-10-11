// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import UIKit

import BigInt
import TrustCore

final class WalletValueOperation: TrustOperation {
    private var balanceProvider: WalletBalanceProvider
    private let keystore: Keystore
    private let wallet: WalletObject

    init(
        balanceProvider: WalletBalanceProvider,
        keystore: Keystore,
        wallet: WalletObject
    ) {
        self.balanceProvider = balanceProvider
        self.keystore = keystore
        self.wallet = wallet
    }

    override func main() {
        _ = balanceProvider.balance().done { [weak self] balance in
            guard let strongSelf = self else {
                self?.finish()
                return
            }
            strongSelf.updateModel(with: balance)
        }
    }

    private func updateModel(with balance: BigInt) {
        keystore.store(object: wallet, fields: [.balance(balance.description)])
        finish()
    }
}
