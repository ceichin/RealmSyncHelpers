//
//  DisposableSyncQuery.swift
//  

import Foundation
import RealmSwift

class DisposableSyncQuery<T: Object> {

    private var previousQuery: SyncQuery<T>?
    private var currentQuery: SyncQuery<T>?

    func sync(query: (Results<T>) -> Results<T>) {
        previousQuery?.unsync()
        previousQuery = currentQuery
        currentQuery = SyncQuery<T>(getQuery: query, name: DisposableSyncQuery.generateName())
        currentQuery?.sync()
    }
    
    func sync(query: (Results<T>) -> Results<T>, notify: NotificationLife, completion: @escaping SyncQueryCompletion<T>) {
        previousQuery?.unsync()
        previousQuery = currentQuery
        currentQuery = SyncQuery<T>(getQuery: query, name: DisposableSyncQuery.generateName())
        currentQuery?.sync(notify: notify, completion: completion)
    }
    
    deinit {
        previousQuery?.unsync()
        currentQuery?.unsync()
    }
    
    private static func generateName() -> String {
        return "\(SyncQueryConstants.disposableSubscriptionNamePrefix)\(UUID().uuidString)"
    }
}
