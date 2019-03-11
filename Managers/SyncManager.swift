//
//  SyncManager.swift
//  

import Foundation
import RealmSwift
import RxSwift

enum SyncStatus {
    case synced
    case syncing
    case notSynced
}

class SyncManager {
    
    static let shared = SyncManager()
    
    var isEverythingSynced = Variable<Bool>(false)
    var syncStatus = Variable<SyncStatus>(.notSynced)
    
    private var isSessionConnected: Bool { return session?.connectionState == .connected }
    private var isSessionActive: Bool { return session?.state == .active }
    private var isReachable: Bool { return ConnectivityManager.shared.isReachable }
    private var session: SyncSession? { return RealmManager.shared.session }
    private var isUploadTransferComplete: Bool = false
    private var isDownloadTransferComplete: Bool = false
    private var uploadProgressToken: NSObject?
    private var downloadProgressToken: NSObject?
    private var sessionNotificationToken: NSObject?
    private var connectionListener: Disposable?

    func initialize() {
        subscribeToSessionConnectionState()
        subscribeToConnectionState()
        subscribeToDownloadProgress()
        subscribeToUploadProgress()
    }
    
    func purgeDisposableQueries() {
        let subscriptions = RealmManager.shared.realm.subscriptions()
        subscriptions.forEach {
            if let name = $0.name, name.hasPrefix(SyncQueryConstants.disposableSubscriptionNamePrefix) {
                $0.unsubscribe()
                print("SyncQuery \"\(name)\" has been purged.")
            }
        }
    }
}

extension SyncManager {
    
    fileprivate func subscribeToConnectionState() {
        connectionListener = ConnectivityManager.shared.status.asObservable().subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            Log.debug(message: "SyncManager - Is reachable: \"\(self.isReachable)\"")
            self.updateSyncedFlag()
        })
    }
    
    fileprivate func subscribeToSessionConnectionState() {
        sessionNotificationToken = session?.observe(\.connectionState) { [weak self] session, change in
            guard let self = self else { return }
            Log.debug(message: "SyncManager - Realm connection state connected: \"\(self.isSessionConnected)\"")
            self.updateSyncedFlag()
        }
    }
    
    fileprivate func subscribeToDownloadProgress() {
        uploadProgressToken = session?.addProgressNotification(for: .upload, mode: .reportIndefinitely) { [weak self] progress in
            guard let self = self else { return }
            self.isUploadTransferComplete = progress.isTransferComplete
            Log.debug(message: "SyncManager - Is donwload complete?: \"\(self.isUploadTransferComplete)\"")
            self.updateSyncedFlag()
        }
    }
    
    fileprivate func subscribeToUploadProgress() {
        downloadProgressToken = session?.addProgressNotification(for: .download, mode: .reportIndefinitely) { [weak self] progress in
            guard let self = self else { return }
            self.isDownloadTransferComplete = progress.isTransferComplete
            Log.debug(message: "SyncManager - Is upload complete?: \"\(self.isDownloadTransferComplete)\"")
            self.updateSyncedFlag()
        }
    }
    
    private func updateSyncedFlag() {
        let isTransferComplete = isUploadTransferComplete && isDownloadTransferComplete
        let isServerConnected = isReachable && isSessionConnected && isSessionActive
        
        if isServerConnected && isTransferComplete {
            StatusBar.backgroundColor = .clear
            syncStatus.value = .synced
        } else if isServerConnected && !isTransferComplete {
            StatusBar.backgroundColor = .yellow
            syncStatus.value = .syncing
        } else {
            StatusBar.backgroundColor = .red
            syncStatus.value = .notSynced
        }

        isEverythingSynced.value = syncStatus.value == .synced
        Log.debug(message: "SyncManager - Sync status changed to: \"\(syncStatus.value)\"")
    }
}
