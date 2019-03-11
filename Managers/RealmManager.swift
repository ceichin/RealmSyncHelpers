//
//  RealmManager.swift
//  

import Foundation
import RealmSwift

class RealmManager {
    
    // MARK: - Constants & Vars
    
    static var shared = RealmManager()
    
    struct Constants {
        static let realmObjectServerUrl = "blabla.us1a.cloud.realm.io"
        static let realmAuthUrl  = URL(string: "https://\(realmObjectServerUrl)")!
        static let realmUrl = URL(string: "realms://\(realmObjectServerUrl)/blabla")!
    }
    
    var realm: Realm {
        return try! Realm()
    }
    
    var isLoggedin: Bool {
        return SyncUser.current != nil
    }
    
    var session: SyncSession? {
        return SyncUser.current?.allSessions().first
    }
    
    // MARK: - Public Methods

    func logout() {
        SyncUser.all.forEach {
            $0.value.logOut()
        }
        deleteRealmFile()
    }
    
    func login(token: String, completion: @escaping ActionResult<Bool>) {
        Log.info(message: "Logging in...")
        logout()
        
        let creds = SyncCredentials.jwt(token)
        SyncUser.logIn(with: creds, server: Constants.realmAuthUrl) { [weak self] (user, err) in
            if let _ = user {
                self?.configureRealmAndOpen()
                Log.info(message: "Logged in successfully!")
                completion(true)
            } else if let error = err {
                Log.error(message: "Log in error", error: error)
                completion(false)
            } else {
                Log.error(message: "Log in error, error unknown.")
                completion(false)
            }
        }
    }
    
    func configureRealmAndOpen() {
        guard let user = SyncUser.current else { return }
        let syncConfig = user.configuration(realmURL: Constants.realmUrl, fullSynchronization: false)
        Realm.Configuration.defaultConfiguration = syncConfig
        Log.debug(message: "Realm opened")
    }
    
    private func deleteRealmFile() {
        guard let url = Realm.Configuration.defaultConfiguration.fileURL else { return }
        File.deleteFileIfExists(url)
    }
}
