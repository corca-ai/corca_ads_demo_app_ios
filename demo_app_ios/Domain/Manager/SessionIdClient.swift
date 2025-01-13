//
//  SessionIdClient.swift
//  demo_app_ios
//
//  Created by 김민식 on 1/13/25.
//

import Foundation

public typealias SessionID = String

public protocol SessionLoader {
    var identifier: SessionID { get }
}

public final class SessionClient: SessionLoader {
    public static let instance = SessionClient()
    public private(set) var identifier: String
    
    public init() {
        self.identifier = UUID().uuidString
    }
    
    public func loadSession(completion: ((SessionID) -> Void)) {
        completion(identifier)
    }
}
