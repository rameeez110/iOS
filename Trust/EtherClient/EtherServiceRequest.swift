// Copyright DApps Platform Inc. All rights reserved.
// Copyright Ether-1 Developers. All rights reserved.
// Copyright Xerom Developers. All rights reserved.

import APIKit
import Foundation
import JSONRPCKit

struct EtherServiceRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
    let batch: Batch
    let server: RPCServer
    typealias Response = Batch.Responses

    var timeoutInterval: Double

    init(
        for server: RPCServer,
        batch: Batch,
        timeoutInterval: Double = 30.0
    ) {
        self.server = server
        self.batch = batch
        self.timeoutInterval = timeoutInterval
    }

    var baseURL: URL {
        return server.rpcURL
    }

    var method: HTTPMethod {
        return .post
    }

    var path: String {
        return "/"
    }

    var parameters: Any? {
        return batch.requestObject
    }

    func intercept(urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        urlRequest.timeoutInterval = timeoutInterval
        return urlRequest
    }

    func response(from object: Any, urlResponse _: HTTPURLResponse) throws -> Response {
        return try batch.responses(from: object)
    }
}
