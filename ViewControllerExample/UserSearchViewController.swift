//
//  UserSearchViewController.swift
//  

import Foundation
import RealmSwift

class UserSearchViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Constants & Vars

    var users = RealmManager.shared.realm.objects(User.self)
    var filteredUsers: Results<User>?
    let searchController = UISearchController(searchResultsController: nil)
    let query = DisposableSyncQuery<User>()
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchBar()
        configureTable()
    }

    // MARK: - Private Methods
    
    private func configureSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by username"
        navigationItem.searchController = searchController
    }
    
    private func configureTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}

// MARK: - Table View

extension UserSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredUsers?.count ?? 0
        }
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let user: User?
        if isFiltering() {
            user = filteredUsers?[indexPath.row]
        } else {
            user = users[indexPath.row]
        }
        cell.textLabel!.text = user?.username
        return cell
    }
}

// MARK: - Search Results Updating Delegate

extension UserSearchViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if isFiltering() {
            let text = searchController.searchBar.text!
            query.sync(query: { $0.filter("username CONTAINS '\(text)'") }, notify: .oneTime) { [weak self] result in
                guard let self = self else { return }
                print(RealmManager.shared.realm.subscriptions())
                switch result {
                case .synced(let results):
                    self.filteredUsers = results
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                case .failed, .noConnection:
                    print("errorrrr")
                }
            }
        }
        
    }
}
