// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import Foundation
import RealmSwift

class RPCStore {
    var endpoints: Results<CustomRPC> {
        return realm.objects(CustomRPC.self)
    }

    let realm: Realm
    init(
        realm: Realm
    ) {
        self.realm = realm
    }

    func add(endpoints: [CustomRPC]) {
        realm.beginWrite()
        realm.add(endpoints, update: true)
        try! realm.commitWrite()
    }

    func delete(endpoints: [CustomRPC]) {
        realm.beginWrite()
        realm.delete(endpoints)
        try! realm.commitWrite()
    }
}
