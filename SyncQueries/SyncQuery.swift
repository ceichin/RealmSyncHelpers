//
//  SyncQuery.swift
//  

import Foundation
import RealmSwift
import RxSwift

enum NotificationLife {
    case oneTime
    case indefinetly
}

class SyncQuery<T: Object> {
    
    // MARK: - Constants & Vars

    let name: String
    
    private var query: Results<T>
    private var token: NotificationToken?
    private var subscription: SyncSubscription<T>?
    private var timer: Timer?
    private var connectionListener: Disposable?
    private var isReachable: Bool { return ConnectivityManager.shared.isReachable }
    
    // MARK: - Inits
    
    init(query: Results<T>, name: String) {
        self.query = query
        self.name = name
    }
    
    convenience init(getQuery: (Results<T>) -> Results<T>, name: String) {
        let objects = RealmManager.shared.realm.objects(T.self)
        self.init(query: getQuery(objects), name: name)
    }
    
    // MARK: - Public Methods
    
    func sync() {
        subscription = query.subscribe(named: name)
    }
    
    func sync(notify: NotificationLife, completion: @escaping SyncQueryCompletion<T>) {
        if notify == .oneTime {
            syncAndNotifyOneTime(completion: completion)
        } else {
            syncAndNotifyIndefinetly(completion: completion)
        }
    }
    
    func unsync() {
        doNotNotifyAnymore()
        subscription?.unsubscribe()
    }
    
    deinit {
        doNotNotifyAnymore()
    }
    
    // MARK: - Private Methods
    
    private func syncAndNotifyOneTime(completion: @escaping SyncQueryCompletion<T>) {
        subscription = query.subscribe(named: name)
        
        guard isReachable else {
            doNotNotifyAnymore()
            Log.warning(message: "SyncQuery \"\(self.name)\" failed inmediately because there is no network connection.")
            completion(.noConnection)
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: SyncQueryConstants.timeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.doNotNotifyAnymore()
            Log.warning(message: "SyncQuery \"\(self.name)\" timed out.")
            completion(.noConnection)
        }
        
        token = subscription?.observe(\.state) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .complete:
                self.doNotNotifyAnymore()
                if self.isReachable {
                    Log.debug(message: "SyncQuery \"\(self.name)\" synced successfully.")
                    completion(.synced(results: self.query))
                } else {
                    Log.warning(message: "SyncQuery \"\(self.name)\" failed because there is no network connection after completion.")
                    completion(.noConnection)
                }
            case .error(let error):
                self.doNotNotifyAnymore()
                Log.warning(message: "SyncQuery \"\(self.name)\" failed because of error: \(error.localizedDescription).")
                completion(.failed(error: .unknown(message: error.localizedDescription)))
            case .creating, .invalidated, .pending:
                break
            }
        }
        
        connectionListener = ConnectivityManager.shared.status.asObservable().subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .reachable: break
            default:
                if status == .unknown, self.isReachable { return }
                self.doNotNotifyAnymore()
                Log.warning(message: "SyncQuery \"\(self.name)\" failed because there was a network connection cut.")
                completion(.noConnection)
            }
        })
    }
    
    private func syncAndNotifyIndefinetly(completion: @escaping SyncQueryCompletion<T>) {
        subscription = query.subscribe(named: name)
        token = subscription?.observe(\.state) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .complete:
                if self.isReachable {
                    completion(.synced(results: self.query))
                } else {
                    completion(.noConnection)
                }
            case .error(let error):
                completion(.failed(error: .unknown(message: error.localizedDescription)))
            case .creating, .invalidated, .pending:
                break
            }
        }
        
        if !isReachable {
            completion(.noConnection)
        }
        
        connectionListener = ConnectivityManager.shared.status.asObservable().subscribe(onNext: { status in
            switch status {
            case .reachable: break
            default: completion(.noConnection)
            }
        })
    }
    
    private func doNotNotifyAnymore() {
        timer?.invalidate()
        token?.invalidate()
        connectionListener?.dispose()
    }
}
