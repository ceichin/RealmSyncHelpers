//
//  ConnectivityManager.swift
//  

import Foundation
import Alamofire
import RxSwift

class ConnectivityManager {
    
    typealias Status = NetworkReachabilityManager.NetworkReachabilityStatus
    
    static let shared = ConnectivityManager()
    
    private var networkReachabilityManager = NetworkReachabilityManager()
    
    var isReachable: Bool {
        return networkReachabilityManager?.isReachable ?? false
    }
    
    let status = Variable<Status>(.unknown)
    
    func initialize() {
        networkReachabilityManager?.listener = { self.status.value = $0 }
        networkReachabilityManager?.startListening()
    }
}
