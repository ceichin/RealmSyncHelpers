//
//  SyncQueryResult.swift
//  

import Foundation
import RealmSwift

typealias SyncQueryCompletion<T: Object> = (SyncQueryResult<T>) -> Void

enum SyncQueryResult<T: Object> {
    case synced(results: Results<T>)
    case noConnection
    case failed(error: SyncQueryError)
}

enum SyncQueryError {
    case unknown(message: String)
}
